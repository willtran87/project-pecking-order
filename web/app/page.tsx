"use client";

import { useEffect, useRef, useState } from "react";
import type { ChangeEvent, KeyboardEvent as ReactKeyboardEvent, TouchEvent as ReactTouchEvent } from "react";

type GameDiagnostic = Record<string, unknown>;

type FlockwatchDiagnostic = {
	visible?: boolean;
	current_page?: string;
	current_page_title?: string;
	available_pages?: unknown;
	accessible_text?: string;
	last_feedback?: string;
};

type BrowserStorageCapability = {
	status: "checking" | "persistent" | "best_effort" | "unavailable";
};

type CheckpointDiagnostic = {
	present: boolean;
	status: string;
	dirty: boolean;
	saving: boolean;
	lastError: string;
	lastSavedUnixMsec: number;
	hasCheckpoint: boolean;
	writeSuccessCount: number;
	userfsPersistentHint?: boolean;
};

type PersistencePresentation = {
	tone: "checking" | "saved" | "degraded" | "unavailable";
	headerText: string;
	footerText: string;
	accessibleText: string;
};

type PlayModePreference = "auto" | "focused" | "page";

type AccessibleStatusContext = {
  loaded: boolean;
  loadError: string;
  loadProgress: number;
	persistenceStatus?: string;
};

const INITIAL_BROWSER_STORAGE_CAPABILITY: BrowserStorageCapability = { status: "checking" };
const MAX_PORTABLE_BACKUP_BYTES = 8 * 1024 * 1024;
const PLAYER_PREFERENCES_STORAGE_KEY = "pecking-order.player-preferences";
const MAX_PLAYER_PREFERENCES_BYTES = 512 * 1024;
const EMPTY_CHECKPOINT_DIAGNOSTIC: CheckpointDiagnostic = {
	present: false,
	status: "",
	dirty: false,
	saving: false,
	lastError: "",
	lastSavedUnixMsec: 0,
	hasCheckpoint: false,
	writeSuccessCount: 0,
	userfsPersistentHint: undefined,
};

export default function Home() {
  const gameCanvas = useRef<HTMLCanvasElement>(null);
  const gameStage = useRef<HTMLDivElement>(null);
	const careerBackupInput = useRef<HTMLInputElement>(null);
	const handbookDetails = useRef<HTMLDetailsElement>(null);
  const started = useRef(false);
  const [loaded, setLoaded] = useState(false);
  const [loadProgress, setLoadProgress] = useState(0);
  const [loadError, setLoadError] = useState("");
	const [campaignActive, setCampaignActive] = useState(false);
	const [playModePreference, setPlayModePreference] = useState<PlayModePreference>("auto");
	const [browserStorageCapability, setBrowserStorageCapability] = useState<BrowserStorageCapability>(
		INITIAL_BROWSER_STORAGE_CAPABILITY,
	);
	const [checkpointDiagnostic, setCheckpointDiagnostic] = useState<CheckpointDiagnostic>(
		EMPTY_CHECKPOINT_DIAGNOSTIC,
	);
  const [gameStatus, setGameStatus] = useState(
    "Game loading. Objective: wait for the career file to open.",
  );
	const persistencePresentation = buildPersistencePresentation(
		browserStorageCapability,
		checkpointDiagnostic,
	);
	const focusedPlay = playModePreference === "focused"
		|| (playModePreference === "auto" && campaignActive);

	useEffect(() => {
		let cancelled = false;
		void probeBrowserStorageCapability().then((capability) => {
			if (!cancelled) setBrowserStorageCapability(capability);
		});
		return () => {
			cancelled = true;
		};
	}, []);

	useEffect(() => {
		installPlayerPreferencesBridge();
		const input = careerBackupInput.current;
		if (input) installCareerBackupPickerBridge(input);
		// The Godot WebAssembly runtime is page-scoped and can outlive React's
		// development/refresh effect cleanup. A full navigation creates a new
		// Window anyway, so keep this bridge for the current page lifetime.
	}, []);

	useEffect(() => {
		const requestCheckpoint = createLifecycleCheckpointRequester(
			() => {
				const runtime = window as typeof window & {
					__pecking_order_request_checkpoint?: (reason: string) => unknown;
				};
				return runtime.__pecking_order_request_checkpoint;
			},
		);
		const forwardFocusPause = (unfocused: boolean) => {
			const runtime = window as typeof window & {
				__pecking_order_set_focus_paused?: (paused: boolean) => unknown;
			};
			try {
				runtime.__pecking_order_set_focus_paused?.(unfocused);
			} catch {
				// The native Godot focus notification remains the fallback. A stale
				// page-lifecycle bridge must never break the browser shell.
			}
		};
		const handleVisibilityChange = () => {
			const hidden = document.visibilityState === "hidden";
			forwardFocusPause(hidden);
			if (hidden) {
				requestCheckpoint("web_visibility_hidden");
			}
		};
		const handleWindowBlur = () => forwardFocusPause(true);
		const handleWindowFocus = () => {
			if (document.visibilityState !== "hidden") forwardFocusPause(false);
		};
		const handlePageHide = () => {
			forwardFocusPause(true);
			requestCheckpoint("web_pagehide");
		};
		document.addEventListener("visibilitychange", handleVisibilityChange);
		window.addEventListener("blur", handleWindowBlur);
		window.addEventListener("focus", handleWindowFocus);
		window.addEventListener("pagehide", handlePageHide);
		return () => {
			document.removeEventListener("visibilitychange", handleVisibilityChange);
			window.removeEventListener("blur", handleWindowBlur);
			window.removeEventListener("focus", handleWindowFocus);
			window.removeEventListener("pagehide", handlePageHide);
		};
	}, []);

  useEffect(() => {
    if (started.current) return;
    started.current = true;

		let resizeFrame = 0;
		const fitCanvasToStage = () => {
			window.cancelAnimationFrame(resizeFrame);
			resizeFrame = window.requestAnimationFrame(() => {
				const canvas = gameCanvas.current;
				const stage = gameStage.current;
				if (!canvas || !stage) return;
				const stageWidth = Math.max(1, stage.getBoundingClientRect().width);
				const renderWidth = Math.min(
					2560,
					Math.max(1280, Math.round(stageWidth * Math.max(1, window.devicePixelRatio))),
				);
				const renderHeight = Math.round(renderWidth * 9 / 16);
				if (canvas.width !== renderWidth) canvas.width = renderWidth;
				if (canvas.height !== renderHeight) canvas.height = renderHeight;
			});
		};
		const resizeObserver = typeof ResizeObserver === "undefined"
			? null
			: new ResizeObserver(fitCanvasToStage);
		if (gameStage.current) resizeObserver?.observe(gameStage.current);
		window.addEventListener("resize", fitCanvasToStage, { passive: true });
		window.addEventListener("orientationchange", fitCanvasToStage, { passive: true });
		document.addEventListener("fullscreenchange", fitCanvasToStage);
		fitCanvasToStage();

    const diagnosticRuntime = window as typeof window & {
      __pecking_order_state?: string;
      render_game_to_text?: () => string;
      advanceTime?: (milliseconds: number) => Promise<void>;
    };
    diagnosticRuntime.render_game_to_text = () => diagnosticRuntime.__pecking_order_state ?? JSON.stringify({
      coordinate_system: "Canvas origin is top-left; +x right, +y down; authored stage 1280x720.",
      mode: "godot_canvas",
      loaded: false,
      canvas: gameCanvas.current
        ? { width: gameCanvas.current.width, height: gameCanvas.current.height }
        : null,
      controls: ["click hen", "route file", "E priority peck", "file one check-in", "open Flockwatch roster", "1-3 binder or speed", "N negotiate", "R standard terms", "space pause"],
    });
    diagnosticRuntime.advanceTime = (milliseconds) => new Promise((resolve) => {
      window.setTimeout(resolve, Math.max(0, milliseconds));
    });

    async function startGodot() {
      try {
			installPlayerPreferencesBridge();
        const [, exportedConfig] = await Promise.all([
          loadGodotScript(),
          loadGodotConfig(),
        ]);
        const runtime = window as typeof window & {
          Engine: {
            new (config: Record<string, unknown>): {
              startGame(options: { onProgress: (current: number, total: number) => void }): Promise<void>;
				rtenv?: { HEAP8?: Int8Array };
            };
            getMissingFeatures(options: { threads: boolean }): string[];
          };
          __pecking_order_state?: string;
			__pecking_order_runtime_metrics?: () => { wasmMemoryBytes: number };
          render_game_to_text?: () => string;
          advanceTime?: (milliseconds: number) => Promise<void>;
        };
        const missing = runtime.Engine.getMissingFeatures({ threads: false });
        if (missing.length > 0) throw new Error(`Browser support missing: ${missing.join(", ")}`);

        const canvas = gameCanvas.current;
				fitCanvasToStage();

        const engine = new runtime.Engine({
          ...exportedConfig,
          canvasResizePolicy: 0,
          focusCanvas: true,
        });
        await engine.startGame({
          onProgress(current, total) {
            if (current > 0 && total > 0) setLoadProgress(Math.round((current / total) * 100));
          },
        });
			runtime.__pecking_order_runtime_metrics = () => ({
				wasmMemoryBytes: engine.rtenv?.HEAP8?.buffer.byteLength ?? 0,
			});
				const backupInput = careerBackupInput.current;
				if (backupInput) installCareerBackupPickerBridge(backupInput);
        runtime.render_game_to_text = () => runtime.__pecking_order_state ?? JSON.stringify({
          coordinate_system: "Canvas origin is top-left; +x right, +y down; authored stage 1280x720.",
          mode: "godot_canvas",
          loaded: true,
          canvas: canvas ? { width: canvas.width, height: canvas.height } : null,
          controls: ["click hen", "route file", "E priority peck", "file one check-in", "open Flockwatch roster", "1-3 binder or speed", "N negotiate", "R standard terms", "space pause"],
        });
        setLoaded(true);
      } catch (error) {
        setLoadError(error instanceof Error ? error.message : "The department failed to initialize.");
      }
    }

    void startGodot();
		return () => {
			resizeObserver?.disconnect();
			window.removeEventListener("resize", fitCanvasToStage);
			window.removeEventListener("orientationchange", fitCanvasToStage);
			document.removeEventListener("fullscreenchange", fitCanvasToStage);
			window.cancelAnimationFrame(resizeFrame);
		};
  }, []);

  useEffect(() => {
    const runtime = window as typeof window & {
      render_game_to_text?: () => string;
    };
    const refreshAccessibleGameStatus = () => {
      let renderedState: string | undefined;
      try {
        renderedState = runtime.render_game_to_text?.();
      } catch {
        // A transient bridge read should fall back to the last concise shell
        // state instead of exposing runtime diagnostics to assistive tech.
      }
			let checkpointForSummary = checkpointDiagnostic;
			if (renderedState !== undefined) {
				const state = parseGameDiagnostic(renderedState);
				const nextCampaignActive = campaignHasBegun(state);
				setCampaignActive((current) => (
					current === nextCampaignActive ? current : nextCampaignActive
				));
				checkpointForSummary = checkpointDiagnosticFromValue(state.checkpoint);
				setCheckpointDiagnostic((current) => (
					sameCheckpointDiagnostic(current, checkpointForSummary)
						? current
						: checkpointForSummary
				));
			}
			const persistenceForSummary = buildPersistencePresentation(
				browserStorageCapability,
				checkpointForSummary,
			);
      const summary = buildAccessibleGameStatus(renderedState, {
        loaded,
        loadError,
        loadProgress,
				persistenceStatus: persistenceForSummary.accessibleText,
      });
      setGameStatus((current) => current === summary ? current : summary);
    };

    refreshAccessibleGameStatus();
    const statusPoll = window.setInterval(refreshAccessibleGameStatus, 1500);
    return () => window.clearInterval(statusPoll);
  }, [browserStorageCapability, checkpointDiagnostic, loaded, loadError, loadProgress]);

  function reloadGame() {
    window.location.reload();
  }

	function toggleFocusedPlay() {
		const enteringFocusedPlay = !focusedPlay;
		setPlayModePreference(enteringFocusedPlay ? "focused" : "page");
		if (enteringFocusedPlay) {
			window.requestAnimationFrame(() => gameCanvas.current?.focus());
		}
	}

	function openHandbook() {
		const details = handbookDetails.current;
		if (!details) return;
		details.open = true;
		window.requestAnimationFrame(() => {
			details.scrollIntoView({ block: "start" });
			details.querySelector("summary")?.focus();
		});
	}

	function invokeMobileAction(action: string) {
		const runtime = window as typeof window & {
			__pecking_order_mobile_action?: (actionId: string) => unknown;
		};
		runtime.__pecking_order_mobile_action?.(action);
		gameCanvas.current?.focus({ preventScroll: true });
	}

	function runTouchControl(event: ReactTouchEvent<HTMLButtonElement>, action: () => void) {
		if (event.touches.length === 0) return;
		action();
	}

	function handleCanvasKeyDown(event: ReactKeyboardEvent<HTMLCanvasElement>) {
		if (event.key !== "Tab") return;
		// Tab is a documented in-game action. Browsers otherwise move DOM focus
		// before Godot can observe it, making hen cycling appear intermittent.
		event.preventDefault();
		event.stopPropagation();
		invokeMobileAction("cycle_hen");
	}

  async function enterFullscreen() {
    try {
      await gameStage.current?.requestFullscreen?.();
    } catch {
      // Fullscreen can be denied by embedded or automated browsers. The game is
      // still fully playable in the terminal, so keep focus on the canvas
      // instead of surfacing an unhandled promise rejection over the office.
    } finally {
      gameCanvas.current?.focus();
    }
  }

	async function handleCareerBackupFileSelected(event: ChangeEvent<HTMLInputElement>) {
		const input = event.currentTarget;
		const file = input.files?.[0];
		if (!file) return;
		const restoreCanvasFocus = () => {
			window.requestAnimationFrame(() => gameCanvas.current?.focus());
		};
		const runtime = window as typeof window & {
			__pecking_order_offer_backup?: (
				jsonText: string,
				sourceLabel: string,
				errorMessage?: string,
			) => unknown;
		};
		const offerBackup = runtime.__pecking_order_offer_backup;
		if (typeof offerBackup !== "function") {
			setGameStatus("Career restore held. The game backup validator is not ready.");
			input.value = "";
			restoreCanvasFocus();
			return;
		}

		try {
			if (file.size <= 0) {
				offerBackup("", file.name, "The selected backup is empty.");
			} else if (file.size > MAX_PORTABLE_BACKUP_BYTES) {
				offerBackup("", file.name, "The selected backup exceeds the 8 MiB safety limit.");
			} else {
				const jsonText = await file.text();
				offerBackup(jsonText, file.name, "");
			}
		} catch {
			offerBackup("", file.name, "The selected backup could not be read.");
		} finally {
			input.value = "";
			restoreCanvasFocus();
		}
	}

  return (
    <main
			className={focusedPlay ? "site-shell is-focused-play" : "site-shell"}
			data-play-mode={focusedPlay ? "focused" : "page"}
		>
      <header className="masthead">
        <a className="wordmark" href="#game" aria-label="Pecking Order home">
          <span className="wordmark-egg" aria-hidden="true" />
          <span>
            <strong>PECKING ORDER</strong>
            <small>Egg Yield Bureau</small>
          </span>
        </a>
        <div
			className="system-state"
			aria-label="Career save status"
			data-save-status={persistencePresentation.tone}
		>
          <span className="status-light" aria-hidden="true" />
          {persistencePresentation.headerText}
        </div>
      </header>

      <section className="intro" aria-labelledby="page-title">
        <div>
          <p className="eyebrow">Five-shift probation | Uncapped Senior career</p>
          <h1 id="page-title">Earn your roost.</h1>
        </div>
        <p className="intro-copy">
          Meet Mabel at her claims desk. Route peckwork. Grow the roost. Build
          careers. Secure the grain reserve. Protect the flock. Every decision
          enters your shared permanent coop record.
        </p>
      </section>

      <section id="game" className="game-terminal" aria-label="Playable Pecking Order management career">
        <div className="terminal-bar">
          <div className="terminal-title">
            <span className="terminal-id">PO-EY-01</span>
            Live career file
          </div>
          <div className="terminal-actions">
			<button className="terminal-action-secondary" type="button" onClick={reloadGame}>Reload terminal</button>
						<button className="terminal-action-secondary" type="button" onClick={openHandbook} aria-controls="management-handbook">
							Handbook
						</button>
						<button
							type="button"
							onClick={toggleFocusedPlay}
							aria-pressed={focusedPlay}
							aria-label={focusedPlay ? "Show page information" : "Focus the game"}
						>
							{focusedPlay ? "Page info" : "Focus game"}
						</button>
            <button type="button" onClick={enterFullscreen}>Full screen</button>
          </div>
        </div>

        <p id="game-controls" className="visually-hidden">
          Game controls: click a hen or route control; press Tab to cycle, Enter
          to authorize or sign, 1 through 3 to choose a binder, card, or speed,
          N to inspect negotiated riders, R to restore standard terms, D to keep
          the standard book, C to continue after filing, E for Priority Peck,
          P to fund a Feed Party, O for after-hours pecking, Space to select a
          focused rider or pause, V for Flockwatch, F10 for Coop Settings and
          Controls, and Escape for overview. Controller defaults are A Priority
          Peck, Y Feed Party, X after-hours, Back Flockwatch, Start pause, right
          shoulder cycle hen, B overview, and Guide settings. Controls can be
          rebound from the settings panel.
        </p>
        <p
          id="game-status"
          className="visually-hidden"
          role="status"
          aria-live="polite"
          aria-atomic="true"
        >
          {gameStatus}
        </p>

        <div className="game-stage" ref={gameStage}>
			<input
				ref={careerBackupInput}
				type="file"
				accept=".json,application/json"
				hidden
				tabIndex={-1}
				aria-hidden="true"
				onChange={handleCareerBackupFileSelected}
			/>
          {!loaded && (
            <div className="loading-state">
              <span className="loading-egg" aria-hidden="true" />
              <strong>{loadError ? "Initialization exception" : "Opening career file"}</strong>
              <span>{loadError || loadingStageText(loadProgress)}</span>
              {!loadError && (
                <progress
                  aria-label="Game loading progress"
                  max={100}
                  value={Math.min(loadProgress, 99)}
                >
                  {Math.min(loadProgress, 99)}%
                </progress>
              )}
            </div>
          )}
          <canvas
            id="canvas"
            ref={gameCanvas}
            className={loaded ? "game-canvas is-loaded" : "game-canvas"}
            tabIndex={0}
						onKeyDown={handleCanvasKeyDown}
						aria-keyshortcuts="1 2 3 Enter N R D C E P O Space V F10 Tab Escape"
            aria-label="Pecking Order playable game"
            aria-describedby="game-controls game-status"
          >
            Your browser does not support the canvas required to run Pecking Order.
          </canvas>
        </div>

		<div className="mobile-touch-controls" aria-label="Touch game controls">
			<button type="button" onTouchStart={(event) => runTouchControl(event, () => invokeMobileAction("pause"))} onClick={(event) => { if (event.detail === 0) invokeMobileAction("pause"); }} aria-label="Pause or resume shift">Pause</button>
			<button type="button" onTouchStart={(event) => runTouchControl(event, () => invokeMobileAction("cycle_hen"))} onClick={(event) => { if (event.detail === 0) invokeMobileAction("cycle_hen"); }} aria-label="Focus next hen">Next hen</button>
			<button type="button" onTouchStart={(event) => runTouchControl(event, () => invokeMobileAction("peck_assist"))} onClick={(event) => { if (event.detail === 0) invokeMobileAction("peck_assist"); }} aria-label="Use Priority Peck">Priority</button>
			<button type="button" onTouchStart={(event) => runTouchControl(event, () => invokeMobileAction("zoom_in"))} onClick={(event) => { if (event.detail === 0) invokeMobileAction("zoom_in"); }} aria-label="Zoom office in">Zoom +</button>
			<button type="button" onTouchStart={(event) => runTouchControl(event, () => invokeMobileAction("zoom_out"))} onClick={(event) => { if (event.detail === 0) invokeMobileAction("zoom_out"); }} aria-label="Zoom office out">Zoom -</button>
			<button type="button" onTouchStart={(event) => runTouchControl(event, () => invokeMobileAction("flockwatch"))} onClick={(event) => { if (event.detail === 0) invokeMobileAction("flockwatch"); }} aria-label="Open or close Flockwatch">Flockwatch</button>
			<button type="button" onTouchStart={(event) => runTouchControl(event, () => invokeMobileAction("overview"))} onClick={(event) => { if (event.detail === 0) invokeMobileAction("overview"); }} aria-label="Return to office overview">Overview</button>
			<button type="button" onTouchStart={(event) => runTouchControl(event, () => invokeMobileAction("settings"))} onClick={(event) => { if (event.detail === 0) invokeMobileAction("settings"); }} aria-label="Open Coop Settings and Controls">Settings</button>
		</div>

        <div className="terminal-footer">
		  <span className="mobile-play-note">For the clearest mobile view, tap Full screen and rotate to landscape.</span>
		  <span className="career-state" data-save-status={persistencePresentation.tone}>
		    <span className="status-light" aria-hidden="true" />
		    {persistencePresentation.footerText}
		  </span>
		  <details className="control-details">
		    <summary>Controls</summary>
		    <div className="control-menu">
		      <div className="control-grid" aria-label="Keyboard and pointer controls">
		        <span><kbd>Click</kbd> Hen / route file / check-in</span>
		        <span><kbd>E</kbd> Priority peck</span>
		        <span><kbd>Tab</kbd> Cycle hen or control</span>
		        <span><kbd>Esc</kbd> Overview / back</span>
		        <span><kbd>Space</kbd> Pause / resume or select rider</span>
		        <span><kbd>V</kbd> Flockwatch + roster</span>
		        <span><kbd>F10</kbd> Settings + controls</span>
		        <span><kbd>1</kbd>-<kbd>3</kbd> Select binder / card / speed</span>
		        <span><kbd>Enter</kbd> Sign binder / authorize</span>
		        <span><kbd>N</kbd> Negotiated riders</span>
		        <span><kbd>R</kbd> Restore standard terms</span>
		        <span><kbd>D</kbd> Keep standard book</span>
		        <span><kbd>C</kbd> Continue after filing</span>
		        <span><kbd>P</kbd> Feed party</span>
		        <span><kbd>O</kbd> After-hours</span>
		      </div>
		      <p className="controller-controls">
		        Controller: A Priority Peck, Y Feed Party, X after-hours, Back
		        Flockwatch, Start pause, right shoulder cycle hen, B overview,
		        and Guide settings. Rebind any action from Settings + Controls.
		      </p>
		    </div>
		  </details>
        </div>
      </section>

      <section className="handbook" aria-label="Management Handbook">
		<details id="management-handbook" ref={handbookDetails} className="handbook-details">
		  <summary>
		    <span>
		      <span className="handbook-kicker">Optional field reference</span>
		      <strong>Management Handbook</strong>
		    </span>
		    <span className="handbook-summary">Career loop, routing, facilities, and long-term systems</span>
		  </summary>
		  <div className="briefing" aria-label="Management briefing">
		    <article>
		      <span className="briefing-number">01</span>
		      <h2>Clear the daily orders</h2>
		      <p>Choose a morning policy, then clear three probation orders each shift. Quota, shell quality, flock welfare, deadlines, and farmer favor shape one score across all five shifts and recurring Senior quarters.</p>
		    </article>
		    <article>
		      <span className="briefing-number">02</span>
		      <h2>Route the peckwork</h2>
		      <p>Click a hen to inspect her specialty and current file, plus her career, trust, and grievance. Choose AUTO, NEST, PREDATOR, or APPEALS routing. AUTO remains opt-in for each employed hen; choosing a manual tray is an explicit override. Matched specialties clear files faster; a looming deadline may justify an imperfect route. When the claim bar enters its gold window, press E for one of three priority pecks per shift. Use her profile to share credit, coach, or apply pressure within the day&apos;s Rooster Operations check-in allowance. Those choices become evidence when a named hen files a flock petition.</p>
		    </article>
		    <article>
		      <span className="briefing-number">03</span>
		      <h2>Grow the bureau</h2>
		      <p>Between shifts, open Flockwatch to authorize vacant perches, compare applicant specialties, wages, and profiles, then open the Capital Blueprint and Campus Portfolio to commission visible office expansions.</p>
		      <ul className="briefing-list">
		        <li>The Flock Provisions Co-op turns feed into a real supply chain with seasonal quotes, finite bins, spoilage, and visible sacks.</li>
		        <li>Wellness Nest tiers add recovery perches and protect Rested Flock welfare; Training Roost tiers reduce sponsorship cost and production drag. Rooster Operations Office tiers add check-ins but also supervisor payroll and surveillance pressure. IT Coop tiers improve only AUTO-routed work while raising compliance exposure.</li>
		        <li>Flock Relations turns documented strain into named-hen case files: fund a remedy, mediate, file a coercive PIP, or commission arbitration.</li>
		        <li>The Farmer Relations Gallery can turn one real shift into a Layer Profile, Clutch Results Board, or Farmer&apos;s Method campaign; standing, cash effects, and the chosen attribution stay on the permanent wall.</li>
		        <li>The Records Annex raises live-file capacity from 18 to 24, 30, then 36. From Day 3, that opens Farm Mutual folders with disclosed lane mix, timed arrivals, premium, and breach charge. Three-day market seasons begin on Day 6. Successful binders earn standing and Bronze, Silver, then Gold seals that commission three visible Service Coop tiers. Gold accreditation can open a physical Negotiation Room where one rush, specialist, or welfare rider changes the exact settlement.</li>
		        <li>The Farmgate Dispatch Depot stores finished eggs as real lots. File Farmer Pickup, County Auction, Regional Showcase, or Hold the Basket; capacity, shelf life, fees, spoilage, and every crate appear in the office.</li>
		        <li>North Meadow is genuinely player-owned land: buy the parcel, commission circulation and power, choose one of two route-safe pads for an Egg Routing Pod, relocate it later, and add optional cold-chain capacity. Every filing changes the visible campus and its recurring costs.</li>
		        <li>The Campus Portfolio extends North Meadow&apos;s shared utilities into Orchard Row and Creekside Yard. File deeds, choose surveyed pads, and queue the Collection Rail Hub, Grain Recovery Mill, Creekside Chilling Exchange, or Contractor Roost for one-to-three-shift construction. Contractor, power, and cold capacity are finite, and a completed module only delivers its economic benefit when an available named hen staffs it.</li>
		      </ul>
		      <p>Feed, payroll, upkeep, arrears, settlements, and signed breach exposure are reserved before spending. When browser storage is available, the terminal checkpoints roster, case, order, and capital decisions. Pass Shift 5 to unlock three-shift Senior quarters, live Career Forecasts, capital policies, annual reviews, and promotion marks you can bank or invest in a named hen&apos;s cross-training.</p>
		    </article>
		  </div>
		</details>
      </section>

      <footer className="site-footer">
        <span>Pecking Order | Probation to Senior career</span>
        <span>All eggs become leadership property upon submission.</span>
      </footer>
    </main>
  );
}

function installPlayerPreferencesBridge() {
	const runtime = window as typeof window & {
		__pecking_order_preferences_bridge?: Readonly<{
			load: () => string;
			save: (payload: string) => boolean;
		}>;
	};
	if (runtime.__pecking_order_preferences_bridge) return;
	runtime.__pecking_order_preferences_bridge = Object.freeze({
		load: () => {
			try {
				const payload = window.localStorage.getItem(PLAYER_PREFERENCES_STORAGE_KEY) ?? "";
				if (new TextEncoder().encode(payload).byteLength > MAX_PLAYER_PREFERENCES_BYTES) return "";
				return payload;
			} catch {
				return "";
			}
		},
		save: (payload: string) => {
			try {
				if (typeof payload !== "string") return false;
				if (new TextEncoder().encode(payload).byteLength > MAX_PLAYER_PREFERENCES_BYTES) return false;
				const parsed: unknown = JSON.parse(payload);
				if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) return false;
				window.localStorage.setItem(PLAYER_PREFERENCES_STORAGE_KEY, payload);
				return window.localStorage.getItem(PLAYER_PREFERENCES_STORAGE_KEY) === payload;
			} catch {
				return false;
			}
		},
	});
}

function installCareerBackupPickerBridge(input: HTMLInputElement): void {
	const runtime = window as typeof window & {
		__pecking_order_choose_backup_file?: () => void;
	};
	runtime.__pecking_order_choose_backup_file = () => {
		// Clearing the value allows the same file to be deliberately selected
		// twice after a cancelled or rejected restore.
		input.value = "";
		input.click();
	};
}

function buildAccessibleGameStatus(
  renderedState: string | undefined,
  context: AccessibleStatusContext,
): string {
	const gameStateStatus = buildGameStateAccessibleStatus(renderedState, context);
	const persistenceStatus = diagnosticPlainText(context.persistenceStatus, 600);
	if (
		persistenceStatus.length === 0
		|| normalizedDiagnosticText(gameStateStatus).includes(normalizedDiagnosticText(persistenceStatus))
	) {
		return gameStateStatus;
	}
	return `${gameStateStatus} ${withTerminalPunctuation(persistenceStatus)}`;
}


function buildGameStateAccessibleStatus(
	renderedState: string | undefined,
	context: AccessibleStatusContext,
): string {
  if (context.loadError) {
    const reason = context.loadError.replace(/\s+/g, " ").trim().slice(0, 160);
    return `Game unavailable. ${reason} Objective: reload the terminal and try again.`;
  }
  if (!context.loaded) {
    const announcedProgress = Math.floor(context.loadProgress / 25) * 25;
    return announcedProgress > 0
      ? `Game loading, ${announcedProgress} percent. Objective: wait for the career file to open.`
      : "Game loading. Objective: wait for the career file to open.";
  }

  const state = parseGameDiagnostic(renderedState);
	const settings = recordValue(state.settings);
	if (settings.visible === true) {
		const summary = stringValue(settings.accessible_text)
			|| "Coop Settings and Controls are open.";
		return `${summary} Objective: adjust a preference or control binding, then choose Return to the Floor.`;
	}
	const capacityCommissioning = recordValue(state.capacity_commissioning);
	if (capacityCommissioning.active === true) {
		const capacity = Math.max(1, Math.trunc(numberValue(capacityCommissioning.capacity, 1)));
		const cost = formatCurrencyFromCents(numberValue(capacityCommissioning.cost_cents, 0));
		const daily = formatCurrencyFromCents(numberValue(
			capacityCommissioning.added_daily_operating_cents,
			0,
		));
		return `Perch ${capacity} commissioned. ${cost} capital filed and ${daily} added to the protected operating reserve each shift. The new workstation is vacant. Objective: review an applicant or return to the office.`;
	}
	const campaignStage = stringValue(state.campaign_stage);
	const senior = recordValue(state.senior_roost);
	const seniorStatus = stringValue(senior.status);
	const seniorActive = seniorStatus.length > 0 && seniorStatus !== "inactive";
	const probationChallengeStatus = seniorActive || campaignStage.startsWith("senior_")
		? ""
		: probationChallengeContractSummary(recordValue(state.challenge_contract));
	const probationDoctrineStatus = seniorActive
		|| campaignStage === "title"
		|| campaignStage.startsWith("senior_")
		? ""
		: probationDoctrineSummary(recordValue(state.probation_doctrine));
	const probationSafeguards = recordValue(state.probation_safeguards);
	const probationSafeguardStatus = seniorActive
		|| campaignStage === "title"
		|| campaignStage.startsWith("senior_")
		? ""
		: probationSafeguardSummary(probationSafeguards);
	const flockwatch = recordValue(state.flockwatch) as FlockwatchDiagnostic;
	if (flockwatch.visible === true) {
		return buildFlockwatchAccessibleStatus(
			flockwatch,
			[probationChallengeStatus, probationDoctrineStatus].filter(Boolean).join(" "),
			probationSafeguardStatus,
			recordValue(state.commendations),
		);
	}
  const campaignDay = Math.max(1, Math.trunc(numberValue(state.campaign_day, 1)));
  const caseDocket = recordValue(state.case_docket);
  const caseDocketId = diagnosticPlainText(stringValue(caseDocket.id), 32);
  const activePrecedents = Array.isArray(caseDocket.active_precedents)
    ? caseDocket.active_precedents.slice(0, 3).map(recordValue)
    : [];
  if (activePrecedents.length === 0) {
    const legacyActivePrecedent = recordValue(caseDocket.active_precedent);
    if (Object.keys(legacyActivePrecedent).length > 0) activePrecedents.push(legacyActivePrecedent);
  }
  const activePrecedentStatus = activePrecedents.map((activePrecedent) => {
    const target = diagnosticPlainText(stringValue(activePrecedent.target_label), 100);
    const strategy = diagnosticPlainText(stringValue(activePrecedent.strategy_label), 80)
      || "pivot opportunity";
    const summary = diagnosticPlainText(stringValue(activePrecedent.summary), 220);
    return summary.length > 0
      ? ` Open ${strategy.toLowerCase()}${target.length > 0 ? ` for ${target}` : ""}: ${summary}`
      : "";
  }).join("");
  const shiftPhase = Math.trunc(numberValue(state.shift_phase, -1));
  const pendingDecision = stringValue(state.pending_decision_kind);
  const pendingDecisionDetail = recordValue(state.pending_decision);
  const firstClutch = recordValue(state.first_clutch);
  const orders = recordValue(state.orders);
  const economy = recordValue(state.economy);
  const production = recordValue(state.production);
  const priorityPeckWorkerId = Math.trunc(numberValue(production.recommended_peck_assist_worker_id, -1));
  const priorityPeckWorkerName = diagnosticPlainText(production.recommended_peck_assist_worker_name, 80)
    || (priorityPeckWorkerId >= 0 ? `hen ${priorityPeckWorkerId + 1}` : "");
  const priorityPeckStatus = priorityPeckWorkerId >= 0
    ? ` Priority Peck ready for ${priorityPeckWorkerName}; press E or use Priority.`
    : "";
  const directFarmTreasury = recordValue(state.farm_treasury);
  const farmTreasury = Object.keys(directFarmTreasury).length > 0
    ? directFarmTreasury
    : recordValue(economy.farm_treasury);
  const farmTreasurySummaryText = farmTreasurySummary(farmTreasury);
  const careerForecast = recordValue(state.career_forecast);
  const careerForecastSummary = seniorCareerForecastSummary(careerForecast);
  const contractBoard = recordValue(state.contract_board);
  const contractPlanning = recordValue(state.contract_planning);
	const flockCare = recordValue(state.flock_care);
	const careGateSummary = flockCareGateSummary(flockCare);
	const careOperationsSummary = flockCareOperationsSummary(flockCare);
	const careActivitySummary = flockCareActivitySummary(flockCare);
	const nextCareSummary = nextFlockCareActionSummary(flockCare);
	const operations = recordValue(state.operations);
	const operationsReview = operationsReviewSummary(operations);
	const operationsActivity = operationsActivitySummary(operations);
	const nextOperationsSummary = nextOperationsActionSummary(operations);
	const flockRelations = recordValue(state.flock_relations);
	const flockRelationsReview = flockRelationsReviewSummary(flockRelations);
	const feedProcurement = recordValue(state.feed_procurement);
	const provisionsSummary = feedProcurementSummary(feedProcurement);
	const farmerRelationsGallery = recordValue(state.farmer_relations_gallery);
	const galleryStatus = stringValue(farmerRelationsGallery.campaign_status)
		|| stringValue(farmerRelationsGallery.status);
	const galleryReview = farmerRelationsGalleryReviewSummary(farmerRelationsGallery);
  const farmgateDispatch = recordValue(state.farmgate_dispatch);
  const farmgateSummary = farmgateDispatchSummary(farmgateDispatch);
  const campusExpansion = recordValue(state.campus_expansion);
  const campusSummary = campusExpansionSummary(campusExpansion);
  const campusPlanner = recordValue(state.campus_expansion_planner);
  const campusPortfolio = recordValue(state.campus_portfolio);
  const campusPortfolioSummaryText = campusPortfolioSummary(campusPortfolio);
  const campusPortfolioPlanner = recordValue(state.campus_portfolio_planner);
  const capitalBlueprint = recordValue(state.capital_blueprint);
  const commissioningReveal = recordValue(state.commissioning_reveal);
  const campusPortfolioReveal = recordValue(state.campus_portfolio_reveal);
  const activeContractCandidate = recordValue(contractBoard.active);
  const activeContract = Object.keys(activeContractCandidate).length > 0
    ? activeContractCandidate
    : recordValue(contractBoard.active_contract);
  const declineReceipt = recordValue(contractBoard.decline_receipt);
  const standing = recordValue(contractBoard.standing);
  const serviceCoopAccreditation = recordValue(contractBoard.accreditation);
  const standingRank = stringValue(standing.rank_label)
    || stringValue(standing.rank_name)
    || stringValue(standing.rank)
    || "Unlisted";
  const standingPoints = Math.max(0, Math.trunc(numberValue(
    standing.points,
    numberValue(standing.score, numberValue(contractBoard.market_standing, 0)),
  )));
  const authoredSeals = Array.isArray(standing.seals)
    ? standing.seals.filter((seal) => recordValue(seal).earned === true).length
    : numberValue(standing.rank_level, 0);
  const standingSeals = Math.max(0, Math.min(3, Math.trunc(authoredSeals)));
  const standingSummary = `Farm Mutual standing ${standingRank}, ${standingPoints} points, ${standingSeals} of 3 seals.`;
  const serviceCoopLevel = Math.max(0, Math.trunc(numberValue(
    serviceCoopAccreditation.level,
    numberValue(contractBoard.service_coop_level, 0),
  )));
  const serviceCoopMaxLevel = Math.max(serviceCoopLevel, Math.trunc(numberValue(
    serviceCoopAccreditation.max_level,
    3,
  )));
  const serviceCoopBonusPercent = Math.max(0, numberValue(
    serviceCoopAccreditation.premium_bonus_percent,
    numberValue(
      serviceCoopAccreditation.premium_bonus_basis_points,
      numberValue(contractBoard.service_coop_premium_bonus_basis_points, 0),
    ) / 100,
  ));
  const serviceCoopSummary = serviceCoopLevel > 0
    ? `Service Coop accreditation level ${serviceCoopLevel} of ${serviceCoopMaxLevel}, adding ${formatPercent(serviceCoopBonusPercent)} to successful binder premiums.`
    : `Service Coop accreditation is not commissioned; successful binder bonus ${formatPercent(serviceCoopBonusPercent)}.`;
  const season = recordValue(contractBoard.season);
  const seasonLabel = stringValue(season.label) || "Baseline Filing";
  const seasonDetail = stringValue(season.summary).replace(/\s+/g, " ").trim();
  const seasonSummary = seasonDetail.length > 0
    ? `${seasonLabel}: ${seasonDetail}`
    : seasonLabel;
  const negotiationCandidate = recordValue(contractBoard.negotiation_room);
  const negotiation = Object.keys(negotiationCandidate).length > 0
    ? negotiationCandidate
    : recordValue(contractBoard.negotiation);
  const negotiationOwned = negotiation.owned === true
    || negotiation.installed === true
    || numberValue(negotiation.level, 0) > 0;
  const negotiationSummary = negotiationOwned
    ? "Gold Negotiation Room commissioned; one rider may be attached to the selected binder."
    : `Gold Negotiation Room not commissioned${stringValue(negotiation.reason).length > 0 ? `: ${stringValue(negotiation.reason)}` : "."}`;
	const probationSafeguardDetailedStatus = seniorActive
		|| campaignStage === "title"
		|| campaignStage.startsWith("senior_")
		? ""
		: probationSafeguardSummary(probationSafeguards, true);
	const probationDoctrineNarration = probationDoctrineStatus.length > 0
		? ` ${probationDoctrineStatus}`
		: "";
	const probationChallengeNarration = probationChallengeStatus.length > 0
		? ` ${probationChallengeStatus}`
		: "";
  const probationSafeguardNarration = probationSafeguardStatus.length > 0
    ? ` ${probationSafeguardStatus}`
    : "";
	const probationSafeguardDetailedNarration = probationSafeguardDetailedStatus.length > 0
		? ` ${probationSafeguardDetailedStatus}`
		: "";
  const seniorYear = Math.max(1, Math.trunc(numberValue(senior.year, 1)));
  const seniorQuarter = Math.max(1, Math.trunc(numberValue(senior.quarter, 1)));
  const seniorShift = Math.max(1, Math.trunc(numberValue(senior.shift_in_quarter, 1)));
	const annualMandateRequired = senior.requires_annual_mandate === true;
	const pendingMandateConfirmation = recordValue(senior.pending_mandate_confirmation);
	const annualMandateProgressSummary = seniorAnnualMandateProgressSummary(senior);
	const annualMandateSettlementSummary = seniorAnnualMandateSettlementSummary(senior);
	const annualStrategyRecapSummary = seniorAnnualStrategyRecapSummary(senior);
	const quarterlyPolicySelectionSummary = seniorQuarterPolicySelectionSummary(senior);
	const sponsorship = recordValue(state.career_sponsorship);
	const sponsorshipVisible = sponsorship.visible === true;
	const sponsorshipMarks = Math.max(0, Math.trunc(numberValue(sponsorship.available_marks, 0)));
	const sponsorshipCost = Math.max(0, Math.trunc(numberValue(sponsorship.mark_cost, 3)));
	const sponsorshipTermsCandidate = recordValue(sponsorship.training_terms);
	const sponsorshipTerms = Object.keys(sponsorshipTermsCandidate).length > 0
		? sponsorshipTermsCandidate
		: recordValue(flockCare.training_terms);
	const sponsorshipFundCost = Math.max(0, Math.trunc(numberValue(
		sponsorshipTerms.effective_sponsorship_cost_cents,
		numberValue(sponsorshipTerms.effective_cost_cents, numberValue(sponsorship.fund_cost_cents, 1200)),
	)));
	const sponsorshipPenalty = trainingWorkPenaltyPercent(sponsorshipTerms);
	const sponsorshipCoachingBonus = Math.max(0, Math.trunc(numberValue(sponsorshipTerms.coaching_xp_bonus, 0)));
	const sponsorshipWageBonus = Math.max(0, Math.trunc(numberValue(sponsorshipTerms.wage_bonus_cents, 100)));
	const sponsorshipTrainingSummary = sponsorshipPenalty <= 0.05
		? "full training throughput"
		: `${formatPlainPercent(sponsorshipPenalty)} training penalty`;
	const sponsorshipReason = stringValue(sponsorship.unavailable_reason).replace(/\s+/g, " ").trim();
	const sponsorshipObjective = sponsorshipVisible
		? sponsorshipReason.length > 0
			? ` Optional Career Sponsorship: ${sponsorshipReason}`
			: ` Optional Career Sponsorship available: bank your ${sponsorshipMarks} marks or invest ${sponsorshipCost} marks and ${formatCurrencyFromCents(sponsorshipFundCost)} in one hen's alternate claim specialty; ${sponsorshipTrainingSummary}, coaching +${sponsorshipCoachingBonus} XP, then +${formatCurrencyFromCents(sponsorshipWageBonus)} daily wage.`
		: "";
  const shiftLabel = seniorActive
    ? `Senior Year ${seniorYear}, Quarter ${seniorQuarter}, Shift ${seniorShift}`
    : `Shift ${campaignDay}`;
  const campusStatus = campusSummary.length > 0 ? ` ${campusSummary}` : "";
  const campusPortfolioStatus = campusPortfolioSummaryText.length > 0
    ? ` ${campusPortfolioSummaryText}`
    : "";
  const farmTreasuryStatus = farmTreasurySummaryText.length > 0
    ? ` ${farmTreasurySummaryText}`
    : "";
  const annualMandateStatus = annualMandateProgressSummary.length > 0
    ? ` ${annualMandateProgressSummary}`
    : "";

  if (commissioningReveal.visible === true) {
    const receipt = recordValue(commissioningReveal.receipt);
    const facility = stringValue(receipt.facility_name) || "Capital facility";
    const level = Math.max(0, Math.trunc(numberValue(receipt.purchased_level, 0)));
    const cost = formatCurrencyFromCents(numberValue(receipt.cost_cents, 0));
    const fundAfter = formatCurrencyFromCents(numberValue(receipt.spendable_after_cents, 0));
    return `Facility commissioned: ${facility}, level ${level}, ${cost} capital filed, ${fundAfter} spendable Feed Fund remains. Objective: continue to the office or return to Capital Blueprint.`;
  }
  if (campusPortfolioReveal.visible === true) {
    const revealDetail = stringValue(campusPortfolioReveal.accessible_text)
      .replace(/\s+/g, " ")
      .trim();
    const narration = revealDetail.length > 0
      ? ` ${revealDetail}`
      : " The accepted campus filing is held over its exact office location.";
    return `Campus build reveal open.${narration} Objective: choose Continue to return to the office, or Return to Portfolio to review the plan.`;
  }
  if (campusPlanner.visible === true) {
    const selected = stringValue(campusPlanner.selected_socket_id).replaceAll("_", " ") || "meadow west";
    const detail = stringValue(campusPlanner.accessible_text).replace(/\s+/g, " ").trim();
    return `Campus Expansion open, ${selected} selected.${detail.length > 0 ? ` ${detail}` : campusStatus}${farmTreasuryStatus} Objective: buy North Meadow, commission services, then place or relocate the Egg Routing Pod on a route-safe socket.`;
  }
  if (campusPortfolioPlanner.visible === true) {
    const selectedParcel = diagnosticTitle(stringValue(campusPortfolioPlanner.selected_parcel_id)) || "campus parcel";
    const selectedPad = diagnosticTitle(stringValue(campusPortfolioPlanner.selected_pad_id)) || "surveyed pad";
    const selectedModule = diagnosticTitle(stringValue(campusPortfolioPlanner.selected_module_id)) || "module file";
    const plannerDetail = stringValue(campusPortfolioPlanner.accessible_text)
      .replace(/\s+/g, " ")
      .trim();
    const canonicalDetail = campusPortfolioSummaryText.length > 0
      ? ` ${campusPortfolioSummaryText}`
      : "";
    const selectionDetail = plannerDetail.length > 0 ? ` ${plannerDetail}` : "";
    return `Campus Portfolio open, ${selectedParcel}, ${selectedPad}, ${selectedModule} selected.${canonicalDetail}${selectionDetail}${farmTreasuryStatus} Objective: compare all three deeds, select a surveyed pad and module, authorize the contractor queue, then assign an available named hen after commissioning. North Meadow utility filings remain under North Meadow Details.`;
  }
  if (capitalBlueprint.visible === true) {
    const selected = stringValue(capitalBlueprint.selected_facility_id)
      .replaceAll("_", " ") || "no parcel";
    const filter = stringValue(capitalBlueprint.active_filter_id) || "all";
    const inspector = stringValue(capitalBlueprint.inspector_text).replace(/\s+/g, " ").trim();
    return `Capital Blueprint open, ${filter} filter, ${selected} selected.${inspector.length > 0 ? ` ${inspector}` : ""}${farmTreasuryStatus} Objective: compare gates and obligations, then preview, pin, or commission the selected parcel.`;
  }

  if (campaignStage === "title") {
		const intakePhase = stringValue(state.campaign_intake_phase);
		const selectedNewContract = recordValue(state.selected_new_challenge_contract);
		const selectedTerms = probationChallengeContractSummary(
			Object.keys(selectedNewContract).length > 0
				? selectedNewContract
				: recordValue(state.challenge_contract),
			true,
			"New file selection",
		);
		const resumeAvailable = state.resume_available === true;
		let resumeTerms = "";
		if (resumeAvailable && state.resume_senior_roost === true) {
			resumeTerms = " A saved Senior career candidate is available; Continue will verify and open it.";
		} else if (resumeAvailable) {
			const resumeLabel = probationChallengeContractLabel(
				recordValue(state.resume_challenge_contract),
			);
			resumeTerms = resumeLabel.length > 0
				? ` A resumable file candidate is available under ${resumeLabel}; Continue will verify and open it.`
				: " A resumable file candidate is available, but its filing standard could not be verified.";
		}
		if (resumeAvailable && intakePhase !== "new_file") {
			return `Campaign menu open.${resumeTerms} Objective: continue the saved-file candidate, or review a new file.`;
		}
		const savedCandidateNote = resumeAvailable
			? " The saved-file candidate remains unchanged until replacement is confirmed."
			: "";
		return `Campaign menu open.${selectedTerms.length > 0 ? ` ${selectedTerms}` : ""}${savedCandidateNote} Objective: choose a filing standard, then meet Mabel and open the new career file${resumeAvailable ? ", or return to the saved-file candidate" : ""}.`;
  }
  if (campaignStage === "contract_board") {
    const targetDay = Math.max(1, Math.trunc(numberValue(contractBoard.target_day, campaignDay)));
    if (Object.keys(activeContract).length > 0) {
      const binderName = stringValue(activeContract.short_name)
        || stringValue(activeContract.name)
        || "Farm Mutual binder";
      const required = Math.max(0, Math.trunc(numberValue(activeContract.required_completed, 0)));
      const breach = formatCurrencyFromCents(numberValue(activeContract.breach_cents, 0));
      const premiumSummary = contractPremiumSummary(activeContract);
      const riderSummary = contractClauseSummary(activeContract);
      const signedSeason = stringValue(activeContract.season_label) || seasonLabel;
		const restedStatus = isRestedFlockTerms(activeContract) && careGateSummary.length > 0
			? ` ${careGateSummary}`
			: "";
		return `Farm Mutual planning for Day ${targetDay}, ${signedSeason}. ${standingSummary} ${serviceCoopSummary} ${binderName} signed under ${riderSummary}: ${required} sound or golden folders must be delivered clean and on time; ${premiumSummary}, breach charge ${breach}.${restedStatus} Objective: press C to open the morning briefing.`;
    }
    if (declineReceipt.accepted === true || stringValue(declineReceipt.status) === "declined") {
      return `Farm Mutual planning for Day ${targetDay}, ${seasonLabel}. ${standingSummary} ${serviceCoopSummary} Standard book filed; no outside binder will arrive. Objective: press C to open the morning briefing.`;
    }
    const selectedOfferId = stringValue(contractPlanning.selected_offer_id);
    const effectiveTerms = recordValue(contractPlanning.effective_terms);
    if (selectedOfferId.length > 0 && Object.keys(effectiveTerms).length > 0) {
      const binderName = stringValue(effectiveTerms.short_name)
        || stringValue(effectiveTerms.name)
        || selectedOfferId.replaceAll("_", " ");
      const files = Math.max(0, Math.trunc(numberValue(effectiveTerms.total_claims, 0)));
      const rush = Math.max(0, Math.trunc(numberValue(effectiveTerms.rush_claims, 0)));
      const required = Math.max(0, Math.trunc(numberValue(effectiveTerms.required_completed, 0)));
      const breach = formatCurrencyFromCents(numberValue(effectiveTerms.breach_cents, 0));
      const reserveAfter = formatCurrencyFromCents(numberValue(
        effectiveTerms.spendable_after_reserve_cents,
        numberValue(effectiveTerms.projected_spendable_after_signing_cents, 0),
      ));
      const signState = contractPlanning.can_sign === false
        ? `Signature held: ${stringValue(contractPlanning.hold_reason) || stringValue(effectiveTerms.reason) || "the quoted terms are not currently authorized"}.`
        : "Press Enter to sign these exact terms.";
		const restedStatus = isRestedFlockTerms(effectiveTerms) && careGateSummary.length > 0
			? ` ${careGateSummary}`
			: "";
		return `Farm Mutual planning for Day ${targetDay}, ${seasonSummary}. ${binderName} selected under ${contractClauseSummary(effectiveTerms)}: ${files} folders, ${rush} rush, ${required} clean and on time; ${contractPremiumSummary(effectiveTerms)}, breach charge ${breach}, reserve leaves ${reserveAfter}.${restedStatus} ${negotiationSummary} ${signState} Press N to inspect riders, R for standard terms, or D to keep the standard book.`;
    }
    const offerCount = Array.isArray(contractBoard.offers) ? contractBoard.offers.length : 0;
    const folderSummary = offerCount > 0
      ? `${offerCount} contract folders available. `
      : "Contract folders available. ";
    return `Farm Mutual planning for Day ${targetDay}, ${seasonSummary}. ${standingSummary} ${serviceCoopSummary} ${negotiationSummary} ${folderSummary}Objective: press 1 through 3 to select a binder and inspect its lane mix, timed arrivals, premium, and breach charge; press N to inspect any available rider, Enter to sign the displayed terms, or D to keep the standard book.`;
  }
  if (campaignStage === "farmer") {
		const careSummary = careOperationsSummary.length > 0 ? ` ${careOperationsSummary}` : "";
		const actionSummary = nextCareSummary.length > 0 ? ` ${nextCareSummary}` : "";
		const operationsSummary = operationsReview.length > 0 ? ` ${operationsReview}` : "";
		const operationsAction = nextOperationsSummary.length > 0 ? ` ${nextOperationsSummary}` : "";
		const relationsSummary = flockRelationsReview.length > 0 ? ` ${flockRelationsReview}` : "";
		const feedSummary = provisionsSummary.length > 0 ? ` ${provisionsSummary}` : "";
		const gallerySummary = galleryReview.length > 0 ? ` ${galleryReview}` : "";
		const dispatchSummary = farmgateSummary.length > 0 ? ` ${farmgateSummary}` : "";
		return `${shiftLabel} review: farmer accounting.${careSummary}${actionSummary}${operationsSummary}${operationsAction}${relationsSummary}${feedSummary}${gallerySummary}${dispatchSummary}${farmTreasuryStatus}${annualMandateStatus}${campusStatus}${campusPortfolioStatus}${probationChallengeNarration}${probationDoctrineNarration}${probationSafeguardNarration} Objective: review the farmer's presentation, then open Requisitions to manage capital, provisions, and any named-hen case files; Capital Blueprint compares permanent facilities, North Meadow utilities, and the three-deed Campus Portfolio.`;
  }
  if (campaignStage === "credit") {
		if (["offer_open", "open", "ready"].includes(galleryStatus)) {
			return `${shiftLabel} review: closing credit filed. ${galleryReview} One public campaign is available: Layer Profile, Clutch Results Board, or Farmer's Method. Objective: open Flockwatch, publish one campaign, or continue to skip.`;
		}
		if (["filed", "skipped"].includes(galleryStatus)) {
			const receipt = farmerRelationsGalleryReceiptSummary(farmerRelationsGallery);
			return `${shiftLabel} review: ${receipt || "the public campaign file is closed."} Objective: continue to the shift report.`;
		}
    return `${shiftLabel} review: credit allocation. Objective: authorize a credit decision.`;
  }
  if (campaignStage === "probation") {
    return `Shift ${campaignDay} probation review.${probationChallengeNarration}${probationDoctrineNarration}${probationSafeguardDetailedNarration} Objective: review the filed results and continue.`;
  }
  if (campaignStage === "final") {
    return `Final campaign review open.${probationChallengeNarration}${probationDoctrineNarration}${probationSafeguardDetailedNarration} Objective: review your probation outcome.`;
  }
  if (campaignStage === "senior_annual" || seniorStatus === "annual_review") {
    const score = Math.max(0, Math.trunc(numberValue(recordValue(senior.last_annual_review).score, 0)));
		const careSummary = careGateSummary.length > 0 ? ` ${careGateSummary}` : "";
		const settlementSummary = annualMandateSettlementSummary.length > 0
			? ` ${annualMandateSettlementSummary}`
			: "";
		const strategySummary = annualStrategyRecapSummary.length > 0
			? ` ${annualStrategyRecapSummary}`
			: "";
		return `Senior Year ${seniorYear} annual review, score ${score}.${careSummary}${settlementSummary}${strategySummary}${farmTreasuryStatus} Objective: acknowledge the annual score, strategy receipt, and Board Mandate settlement, then open next-year planning.${sponsorshipObjective}`;
  }
  if (campaignStage === "senior_quarter" || seniorStatus === "quarter_choice") {
		if (seniorStatus === "quarter_choice" && annualMandateRequired) {
			if (Object.keys(pendingMandateConfirmation).length > 0) {
				const pendingName = diagnosticPlainText(
					stringValue(pendingMandateConfirmation.title)
						|| diagnosticTitle(stringValue(pendingMandateConfirmation.id))
						|| "advanced Board Book",
					120,
				);
				const pendingStake = Math.max(0, Math.trunc(numberValue(
					pendingMandateConfirmation.stake_marks,
					0,
				)));
				return `Senior Year ${seniorYear} annual Board Mandate planning. ${pendingName} inspected; ${pendingStake} Roost ${pendingStake === 1 ? "Mark" : "Marks"} will be reserved for the twelve-shift Book. Success returns the stake; failure permanently spends it. Objective: press C to confirm this stake, or press 1 through 3 to inspect a different Book.`;
			}
			return `Senior Year ${seniorYear} annual Board Mandate planning. ${seniorAnnualMandateSelectionSummary(senior)}${farmTreasuryStatus} Objective: press 1 through 3 to inspect a twelve-shift mandate. A no-stake Book files immediately; an advanced stake requires C to confirm before Quarter 1 policy.`;
		}
    return seniorStatus === "quarter_choice"
			? `Senior Year ${seniorYear}, Quarter ${seniorQuarter} planning.${quarterlyPolicySelectionSummary.length > 0 ? ` ${quarterlyPolicySelectionSummary}` : ""}${careGateSummary.length > 0 ? ` ${careGateSummary}` : ""}${operationsReview.length > 0 ? ` ${operationsReview}` : ""}${nextOperationsSummary.length > 0 ? ` ${nextOperationsSummary}` : ""}${provisionsSummary.length > 0 ? ` ${provisionsSummary}` : ""}${annualMandateStatus}${farmTreasuryStatus}${campusStatus}${campusPortfolioStatus} Objective: press 1 through 3 to file one available capital policy after comparing score edge, score watch, and Board fit.${sponsorshipObjective}`
			: `Senior Year ${seniorYear}, Quarter ${seniorQuarter} report.${annualMandateStatus}${farmTreasuryStatus} Objective: review the filed result and continue.`;
  }
  if (firstClutch.first_hen_prelude === true) {
    const firstHenName = stringValue(firstClutch.target_name) || "Mabel";
    return `${shiftLabel} paused for orientation. Objective: open ${firstHenName}'s file before choosing the flock policy.`;
  }
  if (pendingDecisionDetail.visible === true) {
    const decisionTitle = diagnosticPlainText(
      stringValue(pendingDecisionDetail.title) || "Management decision",
      140,
    );
    const decisionBody = diagnosticPlainText(stringValue(pendingDecisionDetail.body), 280);
    const caseMemory = recordValue(pendingDecisionDetail.case_memory);
    const caseMemoryLabel = diagnosticPlainText(stringValue(caseMemory.label), 100);
    const caseMemoryStrategy = diagnosticPlainText(stringValue(caseMemory.strategy_label), 80)
      || "pivot opportunity";
    const caseMemorySummary = diagnosticPlainText(stringValue(caseMemory.summary), 220);
    const caseMemoryStatus = caseMemorySummary.length > 0
      ? ` ${caseMemoryStrategy}${caseMemoryLabel.length > 0 ? `, ${caseMemoryLabel}` : ""}: ${caseMemorySummary}`
      : "";
    const selectedOption = stringValue(pendingDecisionDetail.selected_option_id);
    const decisionOptions = Array.isArray(pendingDecisionDetail.options)
      ? pendingDecisionDetail.options.slice(0, 3).map((value, index) => {
          const option = recordValue(value);
          const optionIndex = Math.max(1, Math.trunc(numberValue(option.index, index + 1)));
          const label = diagnosticPlainText(stringValue(option.label) || `Choice ${optionIndex}`, 100);
          const tagline = diagnosticPlainText(stringValue(option.tagline), 140);
          const pivotActive = option.case_memory_active === true;
          const pivotLabel = diagnosticPlainText(stringValue(option.case_memory_label), 80)
            || "pivot opportunity";
          const pivotStatus = pivotActive ? `; ${pivotLabel.toLowerCase()} active` : "";
          const precedent = recordValue(option.precedent);
          const precedentTarget = diagnosticPlainText(stringValue(precedent.target_label), 100);
          const precedentSummary = diagnosticPlainText(stringValue(precedent.summary), 200);
          const precedentStatus = precedentSummary.length > 0
            ? `; sets precedent${precedentTarget.length > 0 ? ` for ${precedentTarget}` : ""}: ${precedentSummary}`
            : "";
          const costCents = Math.max(0, Math.trunc(numberValue(option.cost_cents, 0)));
          const unavailableReason = diagnosticPlainText(
            stringValue(option.unavailable_reason) || "requirements not met",
            140,
          ).replace(/[.!?]+$/, "");
          const availability = option.available === false
            ? ` unavailable: ${unavailableReason}`
            : costCents > 0 ? `, costs ${formatCurrencyFromCents(costCents)}` : "";
          const selected = selectedOption.length > 0 && selectedOption === stringValue(option.id)
            ? ", selected"
            : "";
          return `${optionIndex}, ${label}${tagline.length > 0 ? `: ${tagline}` : ""}${availability}${selected}${pivotStatus}${precedentStatus}`;
        })
      : [];
    const docketStatus = pendingDecision === "directive" && caseDocketId.length > 0
      ? ` Case docket ${caseDocketId}.`
      : "";
    return `${shiftLabel}.${docketStatus} ${decisionTitle}.${decisionBody.length > 0 ? ` ${decisionBody}` : ""}${caseMemoryStatus}${decisionOptions.length > 0 ? ` Choices: ${decisionOptions.join("; ")}.` : ""} Objective: press 1 through ${Math.max(1, decisionOptions.length)} to inspect a response, then Enter to authorize it.`;
  }
  if (firstClutch.visible === true) {
    const progress = Math.max(0, Math.min(5, Math.trunc(numberValue(firstClutch.progress, 0))));
    const narratedGuidance = diagnosticPlainText(stringValue(firstClutch.guidance), 180);
    const objective = narratedGuidance.length > 0
      ? narratedGuidance.replace(/[.!?]+$/, "") + "."
      : firstClutchObjective(stringValue(firstClutch.stage));
    return `${shiftLabel} running. First Clutch ${progress} of 5. Objective: ${objective}`;
  }
  if (shiftPhase === 0) {
    return `${shiftLabel}. Morning policy pending.${activePrecedentStatus}${probationChallengeNarration}${probationDoctrineNarration}${probationSafeguardNarration} Objective: choose and authorize one policy.`;
  }
  if (shiftPhase === 2 || pendingDecision.length > 0) {
    return `${shiftLabel}. Incident decision pending. Objective: choose and authorize a response.`;
  }
  if (shiftPhase === 3) {
		return `${shiftLabel} complete.${provisionsSummary.length > 0 ? ` ${provisionsSummary}` : ""}${farmgateSummary.length > 0 ? ` ${farmgateSummary}` : ""}${annualMandateStatus}${farmTreasuryStatus}${campusStatus}${campusPortfolioStatus}${probationChallengeNarration}${probationDoctrineNarration}${probationSafeguardNarration} Objective: proceed to the shift review.`;
  }
  if (shiftPhase === 1) {
    if (Object.keys(activeContract).length > 0) {
      const binderName = stringValue(activeContract.short_name)
        || stringValue(activeContract.name)
        || "Farm Mutual binder";
      const completed = Math.max(0, Math.trunc(numberValue(activeContract.timely_sound_completed, 0)));
      const required = Math.max(1, Math.trunc(numberValue(activeContract.required_completed, 1)));
      const premiumSummary = contractPremiumSummary(activeContract);
      const contractObjective = activeContractObjective(activeContract, completed, required);
			const restedStatus = isRestedFlockTerms(activeContract) && careGateSummary.length > 0
				? ` ${careGateSummary}`
				: "";
			const operationsStatus = operationsActivity.length > 0 ? ` ${operationsActivity}` : "";
      const forecastStatus = seniorActive && careerForecastSummary.length > 0
        ? ` ${careerForecastSummary}`
        : "";
			return `${shiftLabel} running. ${binderName}, ${stringValue(activeContract.season_label) || seasonLabel}, ${contractClauseSummary(activeContract)}: ${completed} of ${required} clean folders delivered on time; ${premiumSummary}, paid only on fulfillment.${restedStatus} ${standingSummary} ${serviceCoopSummary}${priorityPeckStatus}${operationsStatus}${forecastStatus}${activePrecedentStatus}${annualMandateStatus}${provisionsSummary.length > 0 ? ` ${provisionsSummary}` : ""}${farmgateSummary.length > 0 ? ` ${farmgateSummary}` : ""}${farmTreasuryStatus}${campusStatus}${campusPortfolioStatus}${probationChallengeNarration}${probationDoctrineNarration}${probationSafeguardNarration} Objective: ${contractObjective}`;
    }
    const onTrack = Math.max(0, Math.trunc(numberValue(orders.on_track, 0)));
    const total = Math.max(0, Math.trunc(numberValue(orders.total, 0)));
    const forecastStatus = seniorActive && careerForecastSummary.length > 0
      ? ` ${careerForecastSummary}`
      : "";
    return total > 0
			? `${shiftLabel} running. ${onTrack} of ${total} ${seniorActive ? "quarter objectives" : "probation orders"} on track.${priorityPeckStatus}${forecastStatus}${activePrecedentStatus}${annualMandateStatus}${careActivitySummary.length > 0 ? ` ${careActivitySummary}` : ""}${operationsActivity.length > 0 ? ` ${operationsActivity}` : ""}${provisionsSummary.length > 0 ? ` ${provisionsSummary}` : ""}${farmgateSummary.length > 0 ? ` ${farmgateSummary}` : ""}${farmTreasuryStatus}${campusStatus}${campusPortfolioStatus}${probationChallengeNarration}${probationDoctrineNarration}${probationSafeguardNarration} Objective: route files and keep the objectives on track.`
			: `${shiftLabel} running.${priorityPeckStatus}${forecastStatus}${activePrecedentStatus}${annualMandateStatus}${careActivitySummary.length > 0 ? ` ${careActivitySummary}` : ""}${operationsActivity.length > 0 ? ` ${operationsActivity}` : ""}${provisionsSummary.length > 0 ? ` ${provisionsSummary}` : ""}${farmgateSummary.length > 0 ? ` ${farmgateSummary}` : ""}${farmTreasuryStatus}${campusStatus}${campusPortfolioStatus}${probationChallengeNarration}${probationDoctrineNarration}${probationSafeguardNarration} Objective: route files and monitor the flock.`;
  }
  return "Game ready. Objective: follow the current in-game guidance.";
}


function buildFlockwatchAccessibleStatus(
	flockwatch: FlockwatchDiagnostic,
	probationDoctrineStatus = "",
	probationSafeguardStatus = "",
	commendations: GameDiagnostic = {},
): string {
	const pageId = diagnosticPlainText(flockwatch.current_page, 80);
	const pageTitle = diagnosticPlainText(flockwatch.current_page_title, 100)
		|| diagnosticTitle(pageId)
		|| "Current filing";
	const availablePages = flockwatchAvailablePageTitles(flockwatch.available_pages);
	const authoredSummary = diagnosticPlainText(flockwatch.accessible_text, 800);
	let detail = flockwatchAccessibleDetail(authoredSummary, pageTitle);
	if (detail.length === 0 && availablePages.length > 0) {
		detail = `Available pages: ${joinDiagnosticList(availablePages)}.`;
	}

	const feedback = diagnosticPlainText(flockwatch.last_feedback, 320);
	const pieces = [`Flockwatch open. Current page: ${pageTitle}.`];
	if (detail.length > 0) pieces.push(withTerminalPunctuation(detail));
	if (
		probationDoctrineStatus.length > 0
		&& !normalizedDiagnosticText(authoredSummary).includes(normalizedDiagnosticText(probationDoctrineStatus))
	) {
		pieces.push(probationDoctrineStatus);
	}
	if (
		normalizedDiagnosticText(pageId) === "today"
		&& probationSafeguardStatus.length > 0
		&& !normalizedDiagnosticText(authoredSummary).includes(normalizedDiagnosticText(probationSafeguardStatus))
	) {
		pieces.push(probationSafeguardStatus);
	}
	const commendationStatus = careerCommendationsSummary(commendations);
	if (
		normalizedDiagnosticText(pageId) === "governance_records"
		&& commendationStatus.length > 0
		&& !normalizedDiagnosticText(authoredSummary).includes(normalizedDiagnosticText(commendationStatus))
	) {
		pieces.push(commendationStatus);
	}
	if (
		feedback.length > 0
		&& !normalizedDiagnosticText(detail).includes(normalizedDiagnosticText(feedback))
	) {
		pieces.push(`Latest notice: ${withTerminalPunctuation(feedback)}`);
	}
	pieces.push("Objective: review the current filing, use the page tabs to change sections, or close Flockwatch to return to the office.");
	return pieces.join(" ");
}


function careerCommendationsSummary(value: unknown): string {
	const commendations = recordValue(value);
	const total = Math.min(100, Math.max(0, Math.trunc(numberValue(commendations.total_count, 0))));
	if (total <= 0) return "";
	const earned = Math.min(total, Math.max(0, Math.trunc(numberValue(commendations.earned_count, 0))));
	if (commendations.complete === true || earned >= total) {
		return `Career commendations: all ${total} filed as permanent recognition; no hidden economy bonus.`;
	}
	const next = recordValue(commendations.next);
	const title = diagnosticPlainText(next.title, 100) || "Career stamp";
	const progress = diagnosticPlainText(next.progress_label, 80);
	return `Career commendations: ${earned} of ${total} filed. Next stamp: ${title}${progress.length > 0 ? `, ${progress}` : ""}. Recognition is permanent and carries no hidden economy bonus.`;
}


function flockwatchAccessibleDetail(authoredSummary: string, pageTitle: string): string {
	if (authoredSummary.length === 0) return "";
	const normalizedPageTitle = normalizedDiagnosticText(pageTitle);
	return authoredSummary
		.split(/(?<=[.!?])\s+/)
		.map((sentence) => sentence.trim())
		.filter((sentence) => {
			const normalized = normalizedDiagnosticText(sentence);
			if (normalized === "flockwatch filing pages.") return false;
			return !(
				normalizedPageTitle.length > 0
				&& normalized.includes(normalizedPageTitle)
				&& (normalized.includes("is current") || normalized.includes("current page"))
			);
		})
		.join(" ");
}


function flockwatchAvailablePageTitles(value: unknown): string[] {
	if (!Array.isArray(value)) return [];
	const titles: string[] = [];
	for (const entry of value) {
		const record = recordValue(entry);
		const authoredTitle = diagnosticPlainText(
			stringValue(record.current_page_title)
				|| stringValue(record.title)
				|| stringValue(record.label),
			100,
		);
		const rawId = diagnosticPlainText(
			typeof entry === "string" ? entry : stringValue(record.id),
			80,
		);
		const title = authoredTitle || diagnosticTitle(rawId);
		if (
			title.length > 0
			&& !titles.some((existing) => normalizedDiagnosticText(existing) === normalizedDiagnosticText(title))
		) {
			titles.push(title);
		}
	}
	return titles;
}


function diagnosticPlainText(value: unknown, maximumLength: number): string {
	if (typeof value !== "string") return "";
	return value
		.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
		.replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
		.replace(/<[^>]*>/g, " ")
		.replace(/[<>]/g, " ")
		.replace(/\s+/g, " ")
		.trim()
		.slice(0, maximumLength);
}


function normalizedDiagnosticText(value: string): string {
	return value.replace(/\s+/g, " ").trim().toLocaleLowerCase();
}


function withTerminalPunctuation(value: string): string {
	return /[.!?]$/.test(value) ? value : `${value}.`;
}


function checkpointDiagnosticFromValue(value: unknown): CheckpointDiagnostic {
	const checkpoint = recordValue(value);
	const present = Object.keys(checkpoint).length > 0;
	const status = diagnosticPlainText(checkpoint.status, 48)
		.toLocaleLowerCase()
		.replace(/[\s-]+/g, "_");
	const lastSavedUnixMsec = Math.min(
		Number.MAX_SAFE_INTEGER,
		Math.max(0, Math.trunc(numberValue(checkpoint.last_saved_unix_msec, 0))),
	);
	const writeSuccessCount = Math.min(
		Number.MAX_SAFE_INTEGER,
		Math.max(0, Math.trunc(numberValue(checkpoint.write_success_count, 0))),
	);
	const userfsPersistentHint = typeof checkpoint.userfs_persistent_hint === "boolean"
		? checkpoint.userfs_persistent_hint
		: undefined;
	return {
		present,
		status,
		dirty: checkpoint.dirty === true,
		saving: checkpoint.saving === true || status === "saving",
		lastError: diagnosticPlainText(checkpoint.last_error, 240),
		lastSavedUnixMsec,
		hasCheckpoint: (
			checkpoint.has_checkpoint === true
			|| writeSuccessCount > 0
			|| lastSavedUnixMsec > 0
		),
		writeSuccessCount,
		userfsPersistentHint,
	};
}


function sameCheckpointDiagnostic(left: CheckpointDiagnostic, right: CheckpointDiagnostic): boolean {
	return (
		left.present === right.present
		&& left.status === right.status
		&& left.dirty === right.dirty
		&& left.saving === right.saving
		&& left.lastError === right.lastError
		&& left.lastSavedUnixMsec === right.lastSavedUnixMsec
		&& left.hasCheckpoint === right.hasCheckpoint
		&& left.writeSuccessCount === right.writeSuccessCount
		&& left.userfsPersistentHint === right.userfsPersistentHint
	);
}


function buildPersistencePresentation(
	storage: BrowserStorageCapability,
	checkpoint: CheckpointDiagnostic,
): PersistencePresentation {
	const storageAccessible = browserStorageAccessibleText(storage);
	const storageFooter = browserStorageFooterText(storage);
	const unavailableStatuses = ["unavailable", "disabled", "unsupported"];
	const failedStatuses = ["failed", "error", "degraded"];
	const checkpointUnavailable = unavailableStatuses.includes(checkpoint.status);
	const checkpointFailed = checkpoint.lastError.length > 0 || failedStatuses.includes(checkpoint.status);
	const runtimePersistenceUnavailable = checkpoint.userfsPersistentHint === false;

	if (storage.status === "unavailable" || checkpointUnavailable || runtimePersistenceUnavailable) {
		const reason = checkpoint.lastError.length > 0
			? ` Last checkpoint error: ${withTerminalPunctuation(checkpoint.lastError)}`
			: "";
		const runtimeReason = runtimePersistenceUnavailable
			? " The game runtime reports that its user filesystem is not persistent; this takes precedence over the generic browser capability probe."
			: "";
		return {
			tone: "unavailable",
			headerText: "Career saving unavailable",
			footerText: "Career saving unavailable",
			accessibleText: `Career saving is unavailable.${runtimeReason}${reason} ${storageAccessible}`.replace(/\s+/g, " ").trim(),
		};
	}
	if (checkpointFailed) {
		const reason = checkpoint.lastError.length > 0
			? ` ${withTerminalPunctuation(checkpoint.lastError)}`
			: "";
		return {
			tone: "degraded",
			headerText: "Career save degraded",
			footerText: `Checkpoint failed | ${storageFooter}`,
			accessibleText: `Career checkpoint failed.${reason} ${storageAccessible}`.replace(/\s+/g, " ").trim(),
		};
	}
	if (checkpoint.saving) {
		return {
			tone: "checking",
			headerText: "Saving career checkpoint",
			footerText: `Saving checkpoint | ${storageFooter}`,
			accessibleText: `Career checkpoint is being saved. ${storageAccessible}`,
		};
	}
	if (checkpoint.dirty) {
		const priorSave = checkpoint.hasCheckpoint
			? " A prior successful checkpoint is recorded."
			: " No successful checkpoint is recorded yet.";
		return {
			tone: "checking",
			headerText: "Unsaved career changes pending",
			footerText: `Checkpoint pending | ${storageFooter}`,
			accessibleText: `Career changes are waiting for the next checkpoint.${priorSave} ${storageAccessible}`,
		};
	}
	if (checkpoint.hasCheckpoint) {
		if (storage.status === "persistent") {
			return {
				tone: "saved",
				headerText: "Career saved | persistent storage",
				footerText: "Saved checkpoint | persistent browser storage",
				accessibleText: "Career checkpoint saved. Browser storage is persistent.",
			};
		}
		if (storage.status === "best_effort") {
			return {
				tone: "saved",
				headerText: "Career saved | best-effort storage",
				footerText: "Saved checkpoint | best-effort browser storage",
				accessibleText: "Career checkpoint saved. Browser storage is available on a best-effort basis and may be cleared by the browser.",
			};
		}
		return {
			tone: "checking",
			headerText: "Career saved | checking storage",
			footerText: "Saved checkpoint | checking browser storage",
			accessibleText: "Career checkpoint saved. Browser storage persistence is still being checked.",
		};
	}

	const pendingDetail = checkpoint.present
		? "The game has not reported a successful checkpoint yet."
		: "The game checkpoint bridge has not reported yet.";
	return {
		tone: "checking",
		headerText: "Checkpoint pending",
		footerText: `Checkpoint pending | ${storageFooter}`,
		accessibleText: `Career save status is pending. ${pendingDetail} ${storageAccessible}`,
	};
}


function browserStorageAccessibleText(storage: BrowserStorageCapability): string {
	switch (storage.status) {
		case "persistent":
			return "Browser storage is persistent.";
		case "best_effort":
			return "Browser storage is available on a best-effort basis and may be cleared by the browser.";
		case "unavailable":
			return "Browser storage is unavailable.";
		default:
			return "Browser storage persistence is still being checked.";
	}
}


function browserStorageFooterText(storage: BrowserStorageCapability): string {
	switch (storage.status) {
		case "persistent":
			return "persistent browser storage";
		case "best_effort":
			return "best-effort browser storage";
		case "unavailable":
			return "browser storage unavailable";
		default:
			return "checking browser storage";
	}
}


function classifyBrowserStorageCapability(
	indexedDbAvailable: boolean,
	persisted: boolean | undefined,
): BrowserStorageCapability {
	if (!indexedDbAvailable) return { status: "unavailable" };
	return { status: persisted === true ? "persistent" : "best_effort" };
}


async function probeBrowserStorageCapability(): Promise<BrowserStorageCapability> {
	if (typeof window === "undefined") return INITIAL_BROWSER_STORAGE_CAPABILITY;
	let indexedDbFactory: IDBFactory | undefined;
	try {
		indexedDbFactory = window.indexedDB;
	} catch {
		return { status: "unavailable" };
	}
	if (!indexedDbFactory || !await probeIndexedDbAvailability(indexedDbFactory)) {
		return { status: "unavailable" };
	}

	let persisted: boolean | undefined;
	try {
		const storageManager = typeof navigator === "undefined" ? undefined : navigator.storage;
		if (storageManager && typeof storageManager.persisted === "function") {
			persisted = await storageManager.persisted();
		}
	} catch {
		persisted = undefined;
	}
	return classifyBrowserStorageCapability(true, persisted);
}


function probeIndexedDbAvailability(factory: IDBFactory): Promise<boolean> {
	if (typeof window === "undefined") return Promise.resolve(false);
	return new Promise((resolve) => {
		let settled = false;
		let timeoutId = 0;
		const databaseName = `pecking-order-storage-probe-${Date.now()}-${Math.random().toString(16).slice(2)}`;
		const finish = (available: boolean) => {
			if (settled) return;
			settled = true;
			window.clearTimeout(timeoutId);
			resolve(available);
		};
		timeoutId = window.setTimeout(() => finish(false), 2500);

		let request: IDBOpenDBRequest;
		try {
			request = factory.open(databaseName, 1);
		} catch {
			finish(false);
			return;
		}
		request.onsuccess = () => {
			request.result.close();
			try {
				factory.deleteDatabase(databaseName);
			} catch {
				// A cleanup failure does not invalidate the successful open probe.
			}
			finish(true);
		};
		request.onerror = () => finish(false);
		request.onblocked = () => finish(false);
	});
}


function createLifecycleCheckpointRequester(
	lookupBridge: () => unknown,
): (reason: string) => boolean {
	return (reason: string) => {
		const safeReason = diagnosticPlainText(reason, 64);
		if (safeReason.length === 0) return false;
		try {
			const bridge = lookupBridge();
			if (typeof bridge !== "function") return false;
			const result = bridge(safeReason);
			void Promise.resolve(result).catch(() => undefined);
			return true;
		} catch {
			return false;
		}
	};
}


function probationChallengeContractSummary(
	contract: GameDiagnostic,
	includeCriteria = false,
	heading = "Probation filing standard",
): string {
	const label = probationChallengeContractLabel(contract);
	if (label.length === 0) return "";
	let summary = `${heading}: ${label}.`;
	if (!includeCriteria) return summary;
	const criteria = recordValue(contract.criteria);
	const score = Math.trunc(numberValue(criteria.minimum_score, numberValue(criteria.score, 60)));
	const welfare = Math.trunc(numberValue(criteria.minimum_welfare, numberValue(criteria.welfare, 45)));
	const compliance = Math.trunc(numberValue(criteria.minimum_compliance, numberValue(criteria.compliance, 55)));
	const favor = Math.trunc(numberValue(criteria.minimum_farmer_favor, numberValue(criteria.farmer_favor, 50)));
	const crackBasisPoints = Math.trunc(numberValue(
		criteria.maximum_crack_rate_basis_points,
		numberValue(
			criteria.max_crack_rate_basis_points,
			numberValue(criteria.crack_rate_basis_points, 2500),
		),
	));
	summary += ` Final terms require score ${score}, welfare ${welfare}, compliance ${compliance}, farmer favor ${favor}, and shell cracks at or below ${(crackBasisPoints / 100).toFixed(2)} percent.`;
	const routeGuidance = diagnosticPlainText(contract.route_guidance, 320);
	if (routeGuidance.length > 0) {
		summary += ` Route guidance: ${withTerminalPunctuation(routeGuidance)}`;
	}
	return summary;
}


function probationChallengeContractLabel(contract: GameDiagnostic): string {
	const id = diagnosticPlainText(contract.id, 80);
	const label = probationDoctrineLabel(
		contract.label || contract.short_label || diagnosticTitle(id),
		100,
	);
	return id.length > 0 ? label : "";
}


function probationSafeguardSummary(
	forecast: GameDiagnostic,
	includeCriteria = false,
): string {
  if (forecast.visible === false) return "";
  const criteria = diagnosticRecordCollection(forecast.criteria);
  if (criteria.length === 0) return "";

  const criteriaCount = Math.max(
    criteria.length,
    Math.trunc(numberValue(forecast.criteria_count, criteria.length)),
  );
  const countedPasses = criteria.filter((criterion) => criterion.pass === true).length;
  const passCount = Math.max(0, Math.min(
    criteriaCount,
    Math.trunc(numberValue(forecast.pass_count, countedPasses)),
  ));
  const completedShifts = Math.max(0, Math.trunc(numberValue(forecast.completed_shifts, 0)));
  const requiredShifts = Math.max(
    1,
    completedShifts,
    Math.trunc(numberValue(forecast.required_shifts, 5)),
  );

  let summary = includeCriteria
		? `Probation safeguards: ${passCount} of ${criteriaCount} currently pass; ${completedShifts} of ${requiredShifts} shifts completed.`
		: `Probation safeguards: ${passCount} of ${criteriaCount} currently pass.`;
  const blocker = recordValue(forecast.largest_recoverable_blocker);
  if (Object.keys(blocker).length > 0) {
    summary += ` Largest recoverable blocker: ${probationSafeguardBlockerSummary(blocker)}.`;
  }
  if (includeCriteria) {
		summary += ` Final terms: ${criteria.map(probationSafeguardCriterionSummary).join("; ")}.`;
	}
  return summary;
}


function probationDoctrineSummary(doctrine: GameDiagnostic): string {
	const milestoneId = diagnosticPlainText(doctrine.milestone_id, 80);
	if (milestoneId.length === 0) return "";

	const doctrineLabel = probationDoctrineLabel(doctrine.label, 80);
	if (doctrineLabel.length === 0) return "";
	const milestoneTitle = probationDoctrineLabel(doctrine.milestone_title, 100)
		|| diagnosticTitle(milestoneId);
	const strengths = probationDoctrineTerms(doctrine.strengths);
	const watchouts = probationDoctrineTerms(doctrine.watchouts);
	let summary = `Active probation doctrine: ${doctrineLabel}, filed through ${milestoneTitle}.`;
	if (strengths.length > 0) summary += ` Strengths: ${joinDiagnosticList(strengths)}.`;
	if (watchouts.length > 0) summary += ` Watch: ${joinDiagnosticList(watchouts)}.`;
	return summary;
}


function probationDoctrineTerms(value: unknown): string[] {
	const candidates = Array.isArray(value)
		? value
		: typeof value === "string"
			? value.split(/[;,|]/)
			: [];
	const terms: string[] = [];
	for (const candidate of candidates) {
		const term = probationDoctrineLabel(candidate, 64);
		if (
			term.length > 0
			&& !terms.some((existing) => normalizedDiagnosticText(existing) === normalizedDiagnosticText(term))
		) {
			terms.push(term);
		}
		if (terms.length === 3) break;
	}
	return terms;
}


function probationDoctrineLabel(value: unknown, maximumLength: number): string {
	const authored = diagnosticPlainText(value, maximumLength);
	if (authored.length === 0) return "";
	return authored === authored.toUpperCase()
		? diagnosticTitle(authored.toLowerCase().replace(/\s+/g, "_"))
		: authored;
}


function probationSafeguardCriterionSummary(criterion: GameDiagnostic): string {
  const label = probationSafeguardLabel(criterion);
  const comparison = stringValue(criterion.comparison) === "maximum" ? "maximum" : "minimum";
  const projectedValue = Math.trunc(numberValue(
    criterion.projected_value,
    numberValue(criterion.current_value, 0),
  ));
  const target = Math.trunc(numberValue(criterion.target, 0));
  const status = criterion.pass === true ? "passes" : "is at risk";
  return `${label} ${status} at ${probationSafeguardValue(criterion, projectedValue)} against a ${comparison} of ${probationSafeguardValue(criterion, target)}, ${probationSafeguardGapSummary(criterion)}`;
}


function probationSafeguardBlockerSummary(blocker: GameDiagnostic): string {
  const comparison = stringValue(blocker.comparison) === "maximum" ? "maximum" : "minimum";
  const projectedValue = Math.trunc(numberValue(
    blocker.projected_value,
    numberValue(blocker.current_value, 0),
  ));
  const target = Math.trunc(numberValue(blocker.target, 0));
  const signedGap = Math.trunc(numberValue(blocker.signed_gap, 0));
  const distance = Math.max(0, Math.trunc(numberValue(
    blocker.distance_to_pass,
    Math.abs(signedGap),
  )));
  const gap = comparison === "maximum"
    ? `${probationSafeguardDistance(blocker, distance)} above maximum`
    : `${probationSafeguardDistance(blocker, distance)} short`;
  return `${probationSafeguardLabel(blocker)}, ${probationSafeguardValue(blocker, projectedValue)} against a ${comparison} of ${probationSafeguardValue(blocker, target)}; ${gap}`;
}


function probationSafeguardGapSummary(criterion: GameDiagnostic): string {
  const comparison = stringValue(criterion.comparison) === "maximum" ? "maximum" : "minimum";
  const signedGap = Math.trunc(numberValue(criterion.signed_gap, 0));
  if (signedGap === 0) return "exactly at the threshold";
  const distance = probationSafeguardDistance(criterion, Math.abs(signedGap));
  if (signedGap < 0) {
    return comparison === "maximum"
      ? `${distance} above maximum`
      : `${distance} short`;
  }
  return comparison === "maximum"
    ? `${distance} below maximum`
    : `${distance} above minimum`;
}


function probationSafeguardValue(criterion: GameDiagnostic, value: number): string {
  if (probationSafeguardUsesBasisPoints(criterion)) {
    return `${(value / 100).toFixed(2)} percent`;
  }
  const unit = stringValue(criterion.unit);
  if (unit.length > 0 && unit !== "points") return `${value} ${unit}`;
  return `${value} ${Math.abs(value) === 1 ? "point" : "points"}`;
}


function probationSafeguardDistance(criterion: GameDiagnostic, distance: number): string {
  if (probationSafeguardUsesBasisPoints(criterion)) {
    const percentagePoints = distance / 100;
    return `${percentagePoints.toFixed(2)} percentage ${distance === 100 ? "point" : "points"}`;
  }
  return `${distance} ${distance === 1 ? "point" : "points"}`;
}


function probationSafeguardUsesBasisPoints(criterion: GameDiagnostic): boolean {
  return stringValue(criterion.metric) === "crack_rate_basis_points"
    || stringValue(criterion.unit) === "basis_points";
}


function probationSafeguardLabel(criterion: GameDiagnostic): string {
  const authored = stringValue(criterion.label).replace(/\s+/g, " ").trim()
    || diagnosticTitle(stringValue(criterion.id));
  if (authored.length === 0) return "Safeguard";
  return authored === authored.toUpperCase()
    ? diagnosticTitle(authored.toLowerCase().replace(/\s+/g, "_"))
    : authored;
}


function seniorCareerForecastSummary(forecast: GameDiagnostic): string {
  if (forecast.visible !== true || stringValue(forecast.mode) !== "senior_roost") return "";
  const score = Math.max(0, Math.trunc(numberValue(forecast.projected_score, 0)));
  const scoreMax = Math.max(1, Math.trunc(numberValue(forecast.score_max, 100)));
  const marks = Math.max(0, Math.trunc(numberValue(forecast.projected_marks, 0)));
  const nextThreshold = Math.trunc(numberValue(forecast.next_mark_threshold, -1));
  const pointsAway = Math.max(0, Math.trunc(numberValue(
    forecast.points_to_next_mark,
    nextThreshold >= 0 ? nextThreshold - score : 0,
  )));
  const largest = recordValue(forecast.largest_recoverable_component);
  const label = stringValue(largest.label).replace(/\s+/g, " ").trim();
  const recoverable = Math.max(0, Math.trunc(numberValue(largest.recoverable_points, 0)));
  const cause = stringValue(largest.cause).replace(/\s+/g, " ").trim();
  let summary = `Career forecast if filed now: ${score} of ${scoreMax}, ${marks} projected Roost ${marks === 1 ? "Mark" : "Marks"}.`;
  summary += nextThreshold >= 0
    ? ` Next mark tier ${nextThreshold}, ${pointsAway} ${pointsAway === 1 ? "point" : "points"} away.`
    : " Top three-mark tier projected.";
  if (label.length > 0 && recoverable > 0) {
    summary += ` Largest recoverable component: ${label}, ${recoverable} ${recoverable === 1 ? "point" : "points"}.`;
    if (cause.length > 0) summary += ` ${cause}`;
  }
  return summary;
}

function seniorAnnualMandateSelectionSummary(senior: GameDiagnostic): string {
	const offers = diagnosticRecordCollection(senior.annual_mandate_offers).slice(0, 3);
	const year = Math.max(1, Math.trunc(numberValue(senior.year, 1)));
	const availableMarks = Math.max(0, Math.trunc(numberValue(senior.available_roost_marks, 0)));
	const mandateSeals = Math.max(0, Math.trunc(numberValue(senior.mandate_seals, 0)));
	const tierRecord = recordValue(senior.mandate_tier_eligibility);
	const eligibleTier = Math.max(0, Math.trunc(numberValue(
		tierRecord.eligible_tier,
		numberValue(senior.eligible_mandate_tier, 0),
	)));
	const availableOffers = offers.filter((offer) => offer.available !== false).length;
	const mastery = recordValue(senior.mandate_mastery);
	const masteredBooks = Math.max(0, Math.trunc(numberValue(mastery.mastered_count, 0)));
	const totalBooks = Math.max(1, Math.trunc(numberValue(mastery.total_count, 7)));
	let summary = `${offers.length || 3} frozen books; ${availableOffers || (offers.length > 0 ? 0 : 1)} available with ${availableMarks} available Roost ${availableMarks === 1 ? "Mark" : "Marks"}. `;
	summary += `${mandateSeals} Board ${mandateSeals === 1 ? "Seal" : "Seals"}, mandate tier ${eligibleTier}.`;
	summary += ` Board Book portfolio: ${masteredBooks} of ${totalBooks} mastered; first clears advance permanent Coop Commendations, while repeat clears remain valid without duplicating recognition.`;
	const priorAnnual = recordValue(senior.last_annual_review);
	if (year > 1 && Object.keys(priorAnnual).length > 0) {
		summary += priorAnnual.passed === true
			? ` Year ${year - 1} cleared; this year's baseline is one egg higher.`
			: " Recovery year terms: baseline plus two eggs and Farmer Favor minus five.";
	}
	if (offers.length === 0) {
		return `${summary} The Standard Board Book remains the no-stake fallback.`;
	}
	const offerDetails = offers.map((offer) => {
		const name = stringValue(offer.name)
			|| diagnosticTitle(stringValue(offer.id))
			|| "Board Mandate";
		const stake = Math.max(0, Math.trunc(numberValue(offer.stake_marks, 0)));
		const seals = Math.max(0, Math.trunc(numberValue(offer.seal_reward, 0)));
		const availability = offer.available === false
			? `locked${stringValue(offer.unavailable_reason).length > 0 ? `: ${stringValue(offer.unavailable_reason)}` : ""}`
			: "available";
		const masteryCount = Math.max(0, Math.trunc(numberValue(offer.mastery_count, 0)));
		const masteryStatus = masteryCount > 0
			? `mastered ${masteryCount} ${masteryCount === 1 ? "time" : "times"}`
			: "new portfolio clear";
		return `${name}, ${masteryStatus}, ${stake === 0 ? "no mark stake" : `${stake}-mark stake`}, ${seals}-seal reward, ${availability}`;
	});
	return `${summary} Choices: ${offerDetails.join("; ")}.`;
}

function seniorQuarterPolicySelectionSummary(senior: GameDiagnostic): string {
	const offers = diagnosticRecordCollection(senior.quarterly_policy_offers).slice(0, 3);
	if (offers.length === 0) return "";
	const details = offers.map((offer, index) => {
		const title = diagnosticPlainText(
			stringValue(offer.title) || diagnosticTitle(stringValue(offer.id)) || `Policy ${index + 1}`,
			80,
		);
		const strategy = recordValue(offer.strategy);
		const edge = diagnosticPlainText(stringValue(strategy.score_edge), 120) || "quarter tradeoff";
		const watch = diagnosticPlainText(stringValue(strategy.score_watch), 120) || "closing ledger";
		const boardFit = diagnosticPlainText(stringValue(strategy.board_fit), 180) || "review the active Board Mandate";
		const priorYearFit = recordValue(strategy.prior_year_fit);
		const priorFitLabel = diagnosticPlainText(stringValue(priorYearFit.fit_label), 60);
		const priorFocus = diagnosticPlainText(stringValue(priorYearFit.focus_detail), 120);
		const priorFitDetail = diagnosticPlainText(stringValue(priorYearFit.fit_detail), 180);
		const priorYearSummary = priorYearFit.visible === true && priorFitLabel.length > 0
			? `, prior-year fit ${priorFitLabel}${priorFocus.length > 0 ? ` for ${priorFocus}` : ""}${priorFitDetail.length > 0 ? `: ${priorFitDetail}` : ""}`
			: "";
		const availability = offer.available === false
			? `held${stringValue(offer.unavailable_reason).length > 0 ? `: ${diagnosticPlainText(stringValue(offer.unavailable_reason), 140)}` : ""}`
			: "available";
		return `${index + 1}, ${title}, score edge ${edge}, score watch ${watch}, Board fit ${boardFit}${priorYearSummary}, ${availability}`;
	});
	return `Quarterly policy choices: ${details.join("; ")}.`;
}

function seniorAnnualMandateProgressSummary(senior: GameDiagnostic): string {
	const progress = recordValue(senior.annual_mandate_progress);
	if (progress.visible !== true) return "";
	const name = stringValue(progress.mandate_name)
		|| stringValue(recordValue(senior.active_annual_mandate).name)
		|| "Annual Board Mandate";
	const shifts = Math.max(0, Math.trunc(numberValue(progress.shifts_recorded, 0)));
	const shiftTarget = Math.max(1, Math.trunc(numberValue(progress.shifts_target, 12)));
	const objectivesMet = Math.max(0, Math.trunc(numberValue(progress.objectives_met, 0)));
	const objectivesTotal = Math.max(0, Math.trunc(numberValue(progress.objectives_total, 0)));
	const stake = Math.max(0, Math.trunc(numberValue(progress.stake_marks, 0)));
	const summary = `Annual Board Mandate ${name}: ${shifts} of ${shiftTarget} annual shifts filed; ${objectivesMet} of ${objectivesTotal} targets currently met; ${stake} Roost ${stake === 1 ? "Mark" : "Marks"} staked.`;
	if (progress.all_targets_met === true) {
		return `${summary} All current targets are met.`;
	}
	const authoredBlocker = recordValue(progress.largest_recoverable_blocker);
	const blocker = Object.keys(authoredBlocker).length > 0
		? authoredBlocker
		: recordValue(progress.next_threshold);
	const label = stringValue(blocker.label).replace(/\s+/g, " ").trim();
	if (label.length === 0) return summary;
	const metric = stringValue(blocker.metric);
	const comparison = stringValue(blocker.comparison) === "maximum" ? "maximum" : "minimum";
	const actual = Math.trunc(numberValue(blocker.actual, 0));
	const target = Math.trunc(numberValue(blocker.target, 0));
	const gap = Math.max(0, Math.trunc(numberValue(blocker.gap, Math.abs(target - actual))));
	return `${summary} Largest blocker: ${label}, ${mandateMetricValue(metric, actual)} against a ${comparison} of ${mandateMetricValue(metric, target)}; ${mandateMetricGap(metric, gap)} ${comparison === "maximum" ? "over" : "short"}.`;
}

function seniorAnnualMandateSettlementSummary(senior: GameDiagnostic): string {
	const annualReview = recordValue(senior.last_annual_review);
	const reviewSettlement = recordValue(annualReview.mandate_settlement);
	const settlement = Object.keys(reviewSettlement).length > 0
		? reviewSettlement
		: recordValue(senior.last_mandate_settlement);
	if (Object.keys(settlement).length === 0) return "";
	const name = stringValue(settlement.mandate_name) || "Annual Board Mandate";
	const stakeReturned = Math.max(0, Math.trunc(numberValue(settlement.stake_returned, 0)));
	const stakeForfeited = Math.max(0, Math.trunc(numberValue(settlement.stake_forfeited, 0)));
	const sealReward = Math.max(0, Math.trunc(numberValue(settlement.seal_reward, 0)));
	const totalSeals = Math.max(0, Math.trunc(numberValue(
		settlement.mandate_seals_after,
		numberValue(senior.mandate_seals, 0),
	)));
	const availableMarks = Math.max(0, Math.trunc(numberValue(
		settlement.available_roost_marks_after,
		numberValue(senior.available_roost_marks, 0),
	)));
	const priorTier = mandateTierForSealCount(Math.max(0, totalSeals - sealReward));
	const earnedTier = mandateTierForSealCount(totalSeals);
	const mastery = recordValue(senior.mandate_mastery);
	const masteredBooks = Math.max(0, Math.trunc(numberValue(mastery.mastered_count, 0)));
	const totalBooks = Math.max(1, Math.trunc(numberValue(mastery.total_count, 7)));
	const mandateId = stringValue(settlement.mandate_id);
	const successCounts = recordValue(senior.mandate_success_counts);
	const masteryCount = Math.max(0, Math.trunc(numberValue(successCounts[mandateId], 0)));
	const portfolioSummary = ` Board Book portfolio: ${masteredBooks} of ${totalBooks} mastered.`;
	const tierUnlock = earnedTier > priorTier
		? ` Advanced mandate tier ${earnedTier} unlocked for next-year planning.`
		: "";
	if (settlement.grandfathered === true) {
		return `Board Mandate settlement: ${name} preserved as a legacy year; no stake or Board Seal changed. ${totalSeals} total Board ${totalSeals === 1 ? "Seal" : "Seals"} and ${availableMarks} available Roost ${availableMarks === 1 ? "Mark" : "Marks"}.${portfolioSummary}`;
	}
	if (settlement.success === true) {
		const masteryResult = masteryCount === 1 ? " New Book mastered." : ` Book refiled ${masteryCount} times.`;
		return `Board Mandate settlement: ${name} fulfilled; ${sealReward} permanent Board ${sealReward === 1 ? "Seal" : "Seals"} earned and ${stakeReturned} staked Roost ${stakeReturned === 1 ? "Mark" : "Marks"} returned. ${totalSeals} total Board ${totalSeals === 1 ? "Seal" : "Seals"} and ${availableMarks} available Roost ${availableMarks === 1 ? "Mark" : "Marks"}.${masteryResult}${portfolioSummary}${tierUnlock}`;
	}
	const failedStake = stakeForfeited > 0
		? `${stakeForfeited} staked Roost ${stakeForfeited === 1 ? "Mark was" : "Marks were"} permanently forfeited`
		: "no Roost Marks were at risk";
	return `Board Mandate settlement: ${name} failed; no Board Seal earned and ${failedStake}. ${totalSeals} total Board ${totalSeals === 1 ? "Seal" : "Seals"} and ${availableMarks} available Roost ${availableMarks === 1 ? "Mark" : "Marks"}.${portfolioSummary}`;
}


function seniorAnnualStrategyRecapSummary(senior: GameDiagnostic): string {
	const recap = recordValue(senior.annual_strategy_recap);
	if (Object.keys(recap).length === 0) return "";
	const policyCounts = recordValue(recap.policy_counts);
	const policyMix = Object.entries(policyCounts)
		.map(([rawLabel, rawCount]) => ({
			label: diagnosticPlainText(rawLabel, 80),
			count: Math.max(0, Math.trunc(numberValue(rawCount, 0))),
		}))
		.filter((entry) => entry.label.length > 0 && entry.count > 0)
		.sort((left, right) => right.count - left.count || left.label.localeCompare(right.label))
		.slice(0, 4)
		.map((entry) => `${entry.label} ${entry.count}`)
		.join(", ");
	const policyCost = Math.max(0, Math.trunc(numberValue(recap.policy_cost_cents, 0)));
	const policyNet = Math.trunc(numberValue(recap.policy_fund_delta_cents, 0));
	const bestQuarter = recordValue(recap.best_quarter);
	const bestQuarterNumber = Math.max(0, Math.trunc(numberValue(
		bestQuarter.quarter_in_year,
		numberValue(bestQuarter.quarter_number, 0),
	)));
	const bestPolicy = diagnosticPlainText(
		stringValue(bestQuarter.policy_title) || diagnosticTitle(stringValue(bestQuarter.policy_id)),
		80,
	);
	const bestScore = Math.max(0, Math.min(100, Math.trunc(numberValue(bestQuarter.score, 0))));
	const focusDetail = diagnosticPlainText(recap.focus_detail, 120);
	const recommendation = diagnosticPlainText(recap.recommendation, 180);
	const pieces: string[] = [];
	if (policyMix.length > 0) pieces.push(`policy mix ${policyMix}`);
	const policyNetLabel = policyNet === 0
		? formatCurrencyFromCents(0)
		: formatSignedCurrencyFromCents(policyNet);
	pieces.push(`${formatCurrencyFromCents(policyCost)} authorized, net ${policyNetLabel}`);
	if (bestQuarterNumber > 0 && bestPolicy.length > 0) {
		pieces.push(`best quarter Q${bestQuarterNumber}, ${bestPolicy}, ${bestScore} of 100`);
	}
	if (focusDetail.length > 0) {
		pieces.push(`${recap.passed === true ? "narrowest clear" : "held back"}: ${focusDetail}`);
	}
	if (recommendation.length > 0) pieces.push(`next move: ${withTerminalPunctuation(recommendation)}`);
	return `Year strategy receipt: ${pieces.join("; ")}`;
}

function mandateTierForSealCount(sealCount: number): number {
	if (sealCount >= 6) return 3;
	if (sealCount >= 3) return 2;
	if (sealCount >= 1) return 1;
	return 0;
}

function mandateMetricValue(metric: string, value: number): string {
	if (["credited_cents", "closing_fund_cents"].includes(metric)) {
		return formatCurrencyFromCents(value);
	}
	if (metric === "crack_rate_basis_points") {
		return formatPlainPercent(value / 100);
	}
	if (["welfare_average", "compliance_average", "farmer_favor_average"].includes(metric)) {
		return formatPlainPercent(value);
	}
	if (["quota_met_shifts", "wage_arrears_shifts"].includes(metric)) {
		return `${value} ${value === 1 ? "shift" : "shifts"}`;
	}
	return `${value}`;
}

function mandateMetricGap(metric: string, value: number): string {
	if (["credited_cents", "closing_fund_cents"].includes(metric)) {
		return formatCurrencyFromCents(value);
	}
	if (metric === "crack_rate_basis_points") {
		return `${formatPlainPercent(value / 100).replace(" percent", "")} percentage ${value === 100 ? "point" : "points"}`;
	}
	if (["welfare_average", "compliance_average", "farmer_favor_average"].includes(metric)) {
		return `${value} percentage ${value === 1 ? "point" : "points"}`;
	}
	if (["quota_met_shifts", "wage_arrears_shifts"].includes(metric)) {
		return `${value} ${value === 1 ? "shift" : "shifts"}`;
	}
	return `${value}`;
}

function farmTreasurySummary(treasury: GameDiagnostic): string {
	if (Object.keys(treasury).length === 0) return "";
	const ratingIndex = Math.max(0, Math.min(2, Math.trunc(numberValue(treasury.credit_rating, 0))));
	const rating = stringValue(treasury.rating_label)
		|| ["Field File", "Steady Ledger", "Prime Roost"][ratingIndex];
	const principal = Math.max(0, Math.trunc(numberValue(treasury.credit_principal_cents, 0)));
	const creditLimit = Math.max(0, Math.trunc(numberValue(treasury.credit_limit_cents, 0)));
	const headroom = Math.max(0, Math.trunc(numberValue(
		treasury.credit_headroom_cents,
		creditLimit - principal,
	)));
	const vendorArrears = Math.max(0, Math.trunc(numberValue(treasury.vendor_arrears_cents, 0)));
	const interestArrears = Math.max(0, Math.trunc(numberValue(treasury.interest_arrears_cents, 0)));
	const liabilities = Math.max(0, Math.trunc(numberValue(
		treasury.total_liabilities_cents,
		principal + vendorArrears + interestArrears,
	)));
	const interestPercent = Math.max(0, numberValue(
		treasury.interest_percent,
		numberValue(treasury.interest_basis_points, 0) / 100,
	));
	let summary = `Farm Treasury ${diagnosticTitle(rating) || rating} rating: ${formatCurrencyFromCents(principal)} principal on a ${formatCurrencyFromCents(creditLimit)} line, ${formatCurrencyFromCents(headroom)} headroom, ${formatPlainPercent(interestPercent)} interest per shift; `;
	if (liabilities <= 0) {
		summary += "no Treasury liabilities.";
	} else {
		const arrears: string[] = [];
		if (vendorArrears > 0) arrears.push(`${formatCurrencyFromCents(vendorArrears)} vendor arrears`);
		if (interestArrears > 0) arrears.push(`${formatCurrencyFromCents(interestArrears)} interest arrears`);
		summary += `${formatCurrencyFromCents(liabilities)} total liabilities`;
		if (arrears.length > 0) summary += `, including ${joinDiagnosticList(arrears)}`;
		summary += ".";
	}
	if (treasury.capital_frozen === true) {
		summary += " Capital filings frozen: the credit line has no headroom while liabilities remain.";
	} else if (typeof treasury.capital_frozen === "boolean") {
		summary += " Capital filings open.";
	}
	return summary;
}

function flockRelationsReviewSummary(relations: GameDiagnostic): string {
	const level = Math.max(0, Math.trunc(numberValue(relations.level, 0)));
	if (level <= 0) return "";
	const capacity = Math.max(0, Math.trunc(numberValue(relations.capacity, level)));
	const openCases = Math.max(0, Math.trunc(numberValue(relations.open_case_count, 0)));
	const limit = Math.max(0, Math.trunc(numberValue(relations.resolution_limit, level)));
	const used = Math.max(0, Math.min(limit, Math.trunc(numberValue(relations.resolutions_used_today, 0))));
	const last = recordValue(relations.last_resolution);
	const lastWorker = stringValue(last.worker_name).replace(/\s+/g, " ").trim();
	const lastAction = stringValue(last.action_label).replace(/\s+/g, " ").trim();
	let summary = `Flock Relations level ${level}: ${openCases} of ${capacity} case ${openCases === 1 ? "slot" : "slots"} open; ${used} of ${limit} review authorizations used.`;
	if (openCases > 0) {
		summary += " Unresolved cases carry obedience, unity, and named-hen grievance pressure into the next closing.";
	}
	if (lastWorker.length > 0 && lastAction.length > 0) {
		summary += ` Last filed disposition: ${lastAction} for ${lastWorker}.`;
	}
	return summary;
}

function farmerRelationsGalleryReviewSummary(gallery: GameDiagnostic): string {
	if (Object.keys(gallery).length === 0) return "";
	const level = Math.max(0, Math.trunc(numberValue(gallery.level, 0)));
	if (level <= 0 && Object.keys(recordValue(gallery.last_receipt)).length === 0) return "";
	const standingState = recordValue(gallery.standing);
	const standingLabel = stringValue(gallery.standing_label)
		|| stringValue(standingState.label)
		|| stringValue(standingState.rank_label)
		|| "Unlisted";
	const standingPoints = Math.max(0, Math.trunc(numberValue(
		gallery.standing_points,
		numberValue(gallery.public_standing, numberValue(standingState.points, 0)),
	)));
	const authoredStandingLabel = stringValue(gallery.public_standing_label);
	const attribution = recordValue(gallery.attribution);
	const attributionStyle = stringValue(attribution.style_label)
		|| stringValue(attribution.style_id).replaceAll("_", " ")
		|| stringValue(gallery.attribution_style).replaceAll("_", " ")
		|| "awaiting closing credit";
	const shiftCandidate = recordValue(gallery.shift_evidence);
	const shift = Object.keys(shiftCandidate).length > 0
		? shiftCandidate
		: recordValue(gallery.frozen_evidence);
	const attributedWorker = (
		stringValue(attribution.worker_name) || stringValue(shift.top_worker_name)
	).replace(/\s+/g, " ").trim();
	const day = Math.max(0, Math.trunc(numberValue(
		gallery.completed_day,
		numberValue(gallery.review_day, numberValue(shift.day, 0)),
	)));
	const eggs = Math.max(0, Math.trunc(numberValue(shift.eggs, 0)));
	const quota = Math.max(0, Math.trunc(numberValue(shift.quota, 0)));
	const cracked = Math.max(0, Math.trunc(numberValue(shift.cracked, 0)));
	const golden = Math.max(0, Math.trunc(numberValue(shift.golden, 0)));
	const attributionSummary = attributedWorker.length > 0
		? `${attributionStyle} for ${attributedWorker}`
		: attributionStyle;
	return `Farmer Relations Gallery level ${level}: public standing ${authoredStandingLabel || standingLabel}, ${standingPoints} points. Closing attribution: ${attributionSummary}. Day ${day} evidence: ${eggs} of ${quota} eggs, ${cracked} cracked, ${golden} golden.`;
}

function farmerRelationsGalleryReceiptSummary(gallery: GameDiagnostic): string {
	const status = stringValue(gallery.campaign_status) || stringValue(gallery.status);
	if (status === "skipped") return "No public campaign was filed for this closed shift.";
	const receipt = recordValue(gallery.last_receipt);
	if (Object.keys(receipt).length === 0) return "";
	const campaignLabel = stringValue(receipt.campaign_label)
		|| stringValue(receipt.campaign_id).replaceAll("_", " ")
		|| "public campaign";
	const standingState = recordValue(gallery.standing);
	const standingPoints = Math.max(0, Math.trunc(numberValue(
		gallery.standing_points,
		numberValue(gallery.public_standing, numberValue(standingState.points, 0)),
	)));
	const standingDelta = Math.trunc(numberValue(
		receipt.standing_delta,
		numberValue(receipt.public_standing_delta, numberValue(receipt.standing_points_delta, 0)),
	));
	const deltaCopy = `${standingDelta >= 0 ? "+" : ""}${standingDelta}`;
	const fundDelta = Math.trunc(numberValue(
		receipt.fund_delta_cents,
		numberValue(receipt.payout_cents, 0) - numberValue(receipt.cost_cents, 0),
	));
	return `Public campaign filed: ${campaignLabel}; standing ${deltaCopy} to ${standingPoints}, Feed Fund ${formatSignedCurrencyFromCents(fundDelta)}.`;
}

function campusExpansionSummary(expansion: GameDiagnostic): string {
	if (Object.keys(expansion).length === 0) return "";
	const parcel = recordValue(expansion.parcel);
	const parcelOwned = parcel.owned === true || expansion.parcel_owned === true;
	if (!parcelOwned && expansion.visible !== true) return "";
	const parcelQuote = recordValue(expansion.parcel_quote);
	const serviceSource = expansion.services;
	const serviceRecords = Array.isArray(serviceSource)
		? serviceSource.map(recordValue)
		: Object.values(recordValue(serviceSource)).map(recordValue);
	const connectedServices = serviceRecords.filter((service) => (
		service.connected === true || service.commissioned === true || service.owned === true
	)).length;
	const serviceTotal = Math.max(3, serviceRecords.length);
	const pod = recordValue(expansion.routing_pod);
	const podPlaced = pod.placed === true || pod.owned === true || expansion.pod_owned === true;
	const podOperational = pod.operational === true || expansion.pod_operational === true;
	const socket = stringValue(
		pod.current_socket_id || pod.socket_id || expansion.pod_socket_id,
	).replaceAll("_", " ");
	const recurring = Math.max(0, Math.trunc(numberValue(
		expansion.current_daily_cost_cents,
		numberValue(expansion.daily_recurring_cents, 0),
	)));
	if (!parcelOwned) {
		const landCost = Math.max(0, Math.trunc(numberValue(
			parcel.purchase_cost_cents,
			numberValue(parcelQuote.cost_cents, 0),
		)));
		const dailyCost = Math.max(0, Math.trunc(numberValue(
			parcel.recurring_cost_cents,
			numberValue(parcelQuote.added_daily_cost_cents, 0),
		)));
		const gate = stringValue(parcel.reason || parcelQuote.reason || expansion.access_gate_reason)
			.replace(/\s+/g, " ")
			.trim();
		return `North Meadow land filing: ${formatCurrencyFromCents(landCost)} capital and ${formatCurrencyFromCents(dailyCost)} per shift.${gate.length > 0 ? ` ${gate}` : " Ready for review."}`;
	}
	const claimBonus = Math.max(0, Math.trunc(numberValue(expansion.claim_capacity_bonus, 0)));
	const coldBonus = Math.max(0, Math.trunc(numberValue(expansion.farmgate_capacity_bonus_eggs, 0)));
	if (!podPlaced) {
		return `North Meadow owned; ${connectedServices} of ${serviceTotal} services commissioned, Egg Routing Pod not placed, recurring cost ${formatCurrencyFromCents(recurring)} per shift.`;
	}
	if (!podOperational) {
		return `Egg Routing Pod placed${socket.length > 0 ? ` at ${socket}` : ""} but offline until circulation and power are commissioned; ${connectedServices} of ${serviceTotal} services connected, recurring cost ${formatCurrencyFromCents(recurring)} per shift.`;
	}
	const coldSummary = coldBonus > 0 ? ` and +${coldBonus} Farmgate cold-storage eggs` : "";
	return `Egg Routing Pod operational${socket.length > 0 ? ` at ${socket}` : ""}: +${claimBonus} live-file capacity${coldSummary}; recurring cost ${formatCurrencyFromCents(recurring)} per shift.`;
}

function campusPortfolioSummary(portfolio: GameDiagnostic): string {
	if (Object.keys(portfolio).length === 0) return "";
	const parcels = diagnosticRecordCollection(portfolio.parcels);
	const modules = diagnosticRecordCollection(
		Array.isArray(portfolio.modules) || Object.keys(recordValue(portfolio.modules)).length > 0
			? portfolio.modules
			: portfolio.module_catalog,
	);
	const projects = diagnosticRecordCollection(portfolio.projects);
	const resources = recordValue(portfolio.resources);
	const contractor = recordValue(portfolio.contractor);
	const network = recordValue(portfolio.network);
	const hasCanonicalProjection = parcels.length > 0
		|| modules.length > 0
		|| projects.length > 0
		|| Object.keys(resources).length > 0
		|| Object.keys(contractor).length > 0
		|| Object.keys(network).length > 0;
	if (!hasCanonicalProjection) {
		const compactSummary = stringValue(portfolio.summary).replace(/\s+/g, " ").trim();
		return compactSummary.length > 0 ? `Campus portfolio: ${compactSummary}.` : "";
	}

	const ownedParcels = parcels.filter((parcel) => parcel.owned === true || parcel.deed_filed === true);
	const waitingParcels = parcels.filter((parcel) => parcel.owned !== true && parcel.deed_filed !== true);
	let deedSummary = `Campus portfolio: ${ownedParcels.length} of ${parcels.length} deeds filed`;
	if (ownedParcels.length > 0) {
		deedSummary += `: ${joinDiagnosticList(ownedParcels.map((parcel) => diagnosticRecordName(parcel, "parcel")))}`;
	}
	if (waitingParcels.length > 0) {
		deedSummary += `; awaiting deed: ${joinDiagnosticList(waitingParcels.map((parcel) => diagnosticRecordName(parcel, "parcel")))}`;
	}
	deedSummary += ".";

	const modulesById = new Map<string, GameDiagnostic>();
	for (const moduleRecord of modules) {
		const moduleId = stringValue(moduleRecord.id) || stringValue(moduleRecord.module_id);
		if (moduleId.length > 0) modulesById.set(moduleId, moduleRecord);
	}
	const projectSummary = projects.length > 0
		? `Construction queue: ${projects.map((project) => {
			const moduleId = stringValue(project.module_id) || stringValue(project.facility_id);
			const moduleRecord = modulesById.get(moduleId) ?? {};
			const name = stringValue(project.module_name)
				|| diagnosticRecordName(moduleRecord, moduleId || "project");
			const status = stringValue(project.status_label)
				|| diagnosticTitle(stringValue(project.status) || "queued").toUpperCase();
			const stage = stringValue(project.stage_label)
				|| diagnosticTitle(stringValue(project.stage_id)).toUpperCase();
			const remaining = Math.max(0, Math.trunc(numberValue(project.remaining_shifts, 0)));
			const lifecycle = [status, stage]
				.filter((label, index, labels) => label.length > 0 && labels.indexOf(label) === index)
				.join(", ");
			return `${name}, ${lifecycle}, ${remaining} ${remaining === 1 ? "shift" : "shifts"} remaining`;
		}).join("; ")}.`
		: "Construction queue clear.";

	const contractorUsed = Math.max(0, Math.trunc(numberValue(
		resources.contractor_used,
		numberValue(contractor.active_slots, 0),
	)));
	const contractorCapacity = Math.max(contractorUsed, Math.trunc(numberValue(
		resources.contractor_capacity,
		numberValue(contractor.capacity_slots, 0),
	)));
	const powerUsed = Math.max(0, Math.trunc(numberValue(
		resources.power_used,
		numberValue(network.power_reserved_units, 0),
	)));
	const powerCapacity = Math.max(powerUsed, Math.trunc(numberValue(
		resources.power_capacity,
		numberValue(network.power_capacity_units, 0),
	)));
	const coldUsed = Math.max(0, Math.trunc(numberValue(
		resources.cold_used,
		numberValue(network.cold_reserved_units, 0),
	)));
	const coldCapacity = Math.max(coldUsed, Math.trunc(numberValue(
		resources.cold_capacity,
		numberValue(network.cold_capacity_units, 0),
	)));
	const fundPieces: string[] = [];
	if (hasDiagnosticKey(resources, "feed_fund_cents")) {
		fundPieces.push(`Feed Fund ${formatCurrencyFromCents(numberValue(resources.feed_fund_cents, 0))}`);
	}
	if (hasDiagnosticKey(resources, "spendable_fund_cents")) {
		fundPieces.push(`spendable ${formatCurrencyFromCents(numberValue(resources.spendable_fund_cents, 0))}`);
	}
	if (hasDiagnosticKey(resources, "protected_reserve_cents")) {
		fundPieces.push(`protected reserve ${formatCurrencyFromCents(numberValue(resources.protected_reserve_cents, 0))}`);
	}
	const fundSummary = fundPieces.length > 0 ? `${fundPieces.join(", ")}; ` : "";
	const resourceSummary = `Portfolio resources: ${fundSummary}contractors ${contractorUsed} of ${contractorCapacity}, power ${powerUsed} of ${powerCapacity}, cold ${coldUsed} of ${coldCapacity}.`;

	const workers = diagnosticRecordCollection(portfolio.workers);
	const workerNames = new Map<string, string>();
	for (const worker of workers) {
		const workerId = worker.id ?? worker.worker_id;
		const workerName = stringValue(worker.name)
			|| stringValue(worker.display_name)
			|| stringValue(worker.worker_name);
		if (workerId !== undefined && workerId !== null && workerName.length > 0) {
			workerNames.set(String(workerId), workerName);
		}
	}
	const assignmentRecords = diagnosticAssignmentCollection(portfolio.assignments);
	const assignments = new Map<string, GameDiagnostic>();
	for (const assignment of assignmentRecords) {
		const moduleId = stringValue(assignment.module_id) || stringValue(assignment.facility_id);
		if (moduleId.length > 0) assignments.set(moduleId, assignment);
	}
	const commissionedModules = modules.filter((moduleRecord) => (
		moduleRecord.installed === true || moduleRecord.commissioned === true || moduleRecord.built === true
	));
	const operationalCount = commissionedModules.filter((moduleRecord) => moduleRecord.operational === true).length;
	const staffingSummary = commissionedModules.length > 0
		? `Campus staffing: ${commissionedModules.map((moduleRecord) => {
			const moduleId = stringValue(moduleRecord.id) || stringValue(moduleRecord.module_id);
			const assignment = assignments.get(moduleId) ?? {};
			const rawWorkerId = moduleRecord.worker_id ?? assignment.worker_id;
			const hasWorkerId = rawWorkerId !== undefined
				&& rawWorkerId !== null
				&& String(rawWorkerId).length > 0
				&& numberValue(rawWorkerId, -1) >= 0;
			const workerName = stringValue(moduleRecord.worker_name)
				|| stringValue(assignment.worker_name)
				|| (hasWorkerId ? workerNames.get(String(rawWorkerId)) ?? "named hen" : "");
			const staffed = moduleRecord.staffed === true || hasWorkerId;
			return `${diagnosticRecordName(moduleRecord, moduleId || "module")} ${staffed ? `staffed by ${workerName || "named hen"}` : "unstaffed"} and ${moduleRecord.operational === true ? "operational" : "offline"}`;
		}).join("; ")}. ${operationalCount} of ${commissionedModules.length} commissioned ${commissionedModules.length === 1 ? "module is" : "modules are"} operational.`
		: "Campus staffing: no portfolio modules commissioned.";

	return `${deedSummary} ${projectSummary} ${resourceSummary} ${staffingSummary}`;
}


function farmgateDispatchSummary(dispatch: GameDiagnostic): string {
	if (Object.keys(dispatch).length === 0 || dispatch.enabled !== true) return "";
	const level = Math.max(1, Math.trunc(numberValue(dispatch.level, 1)));
	const stock = Math.max(0, Math.trunc(numberValue(dispatch.stock_count, 0)));
	const capacity = Math.max(stock, Math.trunc(numberValue(dispatch.storage_capacity_eggs, stock)));
	const stockValue = Math.max(0, Math.trunc(numberValue(dispatch.stock_value_cents, 0)));
	const oldest = Math.max(0, Math.trunc(numberValue(dispatch.oldest_age_shifts, 0)));
	const expiring = Math.max(0, Math.trunc(numberValue(dispatch.expiring_count, 0)));
	const mandate = stringValue(dispatch.active_mandate_label) || "Farmer Pickup default";
	const season = recordValue(dispatch.season);
	const seasonLabel = stringValue(season.label) || "current season";
	const settlement = recordValue(dispatch.last_settlement_receipt);
	const settlementSummary = settlement.accepted === true
		? ` Last settlement sold ${Math.max(0, Math.trunc(numberValue(settlement.sold_eggs, 0)))} eggs for ${formatSignedCurrencyFromCents(numberValue(settlement.settlement_cash_delta_cents, 0))} after route and cold-chain costs.`
		: "";
	const ageSummary = stock > 0
		? ` Oldest lot age ${oldest} ${oldest === 1 ? "shift" : "shifts"}; ${expiring} expiring now.`
		: "";
	return `Farmgate Dispatch level ${level}: ${stock} of ${capacity} eggs in cold store, worth ${formatCurrencyFromCents(stockValue)}; ${mandate} under ${seasonLabel}.${ageSummary}${settlementSummary}`;
}

function feedProcurementSummary(provisions: GameDiagnostic): string {
	if (Object.keys(provisions).length === 0) return "";
	const level = Math.max(0, Math.trunc(numberValue(
		provisions.level,
		numberValue(provisions.facility_level, 0),
	)));
	const stock = Math.max(0, Math.trunc(numberValue(
		provisions.stock_scoops,
		numberValue(provisions.inventory_scoops, numberValue(provisions.stock, 0)),
	)));
	const capacity = Math.max(0, Math.trunc(numberValue(
		provisions.capacity_scoops,
		numberValue(provisions.capacity, 0),
	)));
	const demand = Math.max(0, Math.trunc(numberValue(
		provisions.next_demand_scoops,
		numberValue(provisions.demand_scoops, 0),
	)));
	const coverage = Math.max(0, Math.trunc(numberValue(
		provisions.covered_scoops,
		Math.min(stock, demand),
	)));
	const quote = Math.max(0, Math.trunc(numberValue(
		provisions.spot_price_cents,
		numberValue(
			provisions.spot_unit_price_cents,
			numberValue(provisions.season_quote_cents, numberValue(provisions.quote_cents, 0)),
		),
	)));
	const seasonState = recordValue(provisions.season);
	const season = stringValue(provisions.season_label)
		|| stringValue(seasonState.label)
		|| "current season";
	const spoilage = Math.max(0, Math.trunc(numberValue(
		provisions.spoiled_scoops_total,
		numberValue(provisions.spoiled_total_scoops, numberValue(provisions.spoilage_scoops, 0)),
	)));
	if (level <= 0) {
		return `Flock Provisions is not commissioned; ${demand} feed scoops will be covered automatically on the ${season} spot market at ${formatCurrencyFromCents(quote)} each.`;
	}
	const fallback = Math.max(0, demand - coverage);
	const spoilageSummary = spoilage > 0
		? ` ${spoilage} ${spoilage === 1 ? "scoop has" : "scoops have"} spoiled on the permanent ledger.`
		: "";
	return `Flock Provisions level ${level}: ${stock} of ${capacity} scoops stored, covering ${coverage} of ${demand} next-shift demand; ${fallback} projected spot fallback at ${formatCurrencyFromCents(quote)} per scoop in ${season}.${spoilageSummary}`;
}

function flockCareGateSummary(flockCare: GameDiagnostic): string {
	if (Object.keys(flockCare).length === 0) return "";
	const rested = recordValue(flockCare.rested_flock);
	const welfare = Math.max(0, Math.round(numberValue(
		flockCare.welfare,
		numberValue(flockCare.welfare_score, 0),
	)));
	const gate = Math.max(0, Math.trunc(numberValue(
		flockCare.rested_flock_gate,
		numberValue(rested.minimum, 72),
	)));
	const margin = Math.trunc(numberValue(
		flockCare.welfare_delta_to_gate,
		numberValue(rested.margin, welfare - gate),
	));
	const met = typeof rested.met === "boolean" ? rested.met : margin >= 0;
	return met
		? `Rested Flock welfare ${welfare} of required ${gate}, on track by ${Math.max(0, margin)}.`
		: `Rested Flock welfare ${welfare} of required ${gate}, ${Math.abs(margin)} short.`;
}

function flockCareOperationsSummary(flockCare: GameDiagnostic): string {
	if (Object.keys(flockCare).length === 0) return "";
	const wellnessNest = recordValue(flockCare.wellness_nest);
	const trainingRoost = recordValue(flockCare.training_roost);
	const terms = recordValue(flockCare.training_terms);
	const wellnessLevel = Math.max(0, Math.trunc(numberValue(
		flockCare.wellness_level,
		numberValue(wellnessNest.level, 0),
	)));
	const trainingLevel = Math.max(0, Math.trunc(numberValue(
		flockCare.training_roost_level,
		numberValue(trainingRoost.level, 0),
	)));
	const breaksActive = Math.max(0, Math.trunc(numberValue(
		flockCare.breaks_active,
		numberValue(flockCare.active_breaks, 0),
	)));
	const recoveryPerches = Math.max(0, Math.trunc(numberValue(
		flockCare.recovery_perch_count,
		numberValue(recordValue(flockCare.recovery_effects).break_capacity, 0),
	)));
	const trainingActive = Array.isArray(flockCare.training_active)
		? flockCare.training_active.length
		: Math.max(0, Math.trunc(numberValue(flockCare.training_active, numberValue(flockCare.training_active_count, 0))));
	const effectiveCost = Math.max(0, Math.trunc(numberValue(
		terms.effective_sponsorship_cost_cents,
		numberValue(terms.effective_cost_cents, 1200),
	)));
	const penalty = trainingWorkPenaltyPercent(terms);
	const penaltySummary = penalty <= 0.05
		? "full training throughput"
		: `${formatPlainPercent(penalty)} training penalty`;
	return `Flock care: Wellness Nest level ${wellnessLevel}, ${breaksActive} of ${recoveryPerches} recovery perches occupied; Training Roost level ${trainingLevel}, ${trainingActive} active training ${trainingActive === 1 ? "file" : "files"}, sponsorship ${formatCurrencyFromCents(effectiveCost)}, ${penaltySummary}.`;
}

function flockCareActivitySummary(flockCare: GameDiagnostic): string {
	if (Object.keys(flockCare).length === 0) return "";
	const breaksActive = Math.max(0, Math.trunc(numberValue(flockCare.breaks_active, 0)));
	const trainingActive = Array.isArray(flockCare.training_active)
		? flockCare.training_active.length
		: Math.max(0, Math.trunc(numberValue(flockCare.training_active, numberValue(flockCare.training_active_count, 0))));
	if (breaksActive === 0 && trainingActive === 0) return "";
	return `Flock care active: ${breaksActive} ${breaksActive === 1 ? "hen" : "hens"} recovering and ${trainingActive} training ${trainingActive === 1 ? "file" : "files"} in progress.`;
}

function nextFlockCareActionSummary(flockCare: GameDiagnostic): string {
	const action = recordValue(flockCare.next_care_action);
	if (Object.keys(action).length === 0) return "";
	if (action.complete === true) return "Flock care program fully commissioned.";
	const facilityId = stringValue(action.facility_id) || stringValue(action.id) || "care expansion";
	const displayName = stringValue(action.display_name)
		|| stringValue(action.name)
		|| facilityId.replaceAll("_room", "").replaceAll("_", " ");
	const nextLevel = Math.max(1, Math.trunc(numberValue(action.next_level, numberValue(action.level, 1))));
	const capital = Math.max(0, Math.trunc(numberValue(
		action.capital_cost_cents,
		numberValue(action.next_level_cost_cents, numberValue(action.cost_cents, 0)),
	)));
	const upkeep = Math.trunc(numberValue(
		action.maintenance_delta_cents,
		numberValue(action.upkeep_delta_cents, 0),
	));
	const ready = action.can_purchase === true || action.available === true;
	const reason = stringValue(action.reason) || stringValue(action.action_reason);
	const reasonSummary = !ready && reason.length > 0
		? ` Gate: ${reason.replace(/\s+/g, " ").trim()}`
		: "";
	return `Next care ${ready ? "file" : "gate"}: ${displayName}, level ${nextLevel}, ${formatCurrencyFromCents(capital)} capital and ${formatSignedCurrencyFromCents(upkeep)} daily upkeep.${reasonSummary}`;
}

function operationsReviewSummary(operations: GameDiagnostic): string {
	if (Object.keys(operations).length === 0) return "";
	const supervision = recordValue(operations.supervision);
	const automation = recordValue(operations.automation);
	const roster = Array.isArray(operations.manager_roster)
		? operations.manager_roster.map(recordValue).slice(0, 4)
		: [];
	const density = recordValue(operations.management_density);
	const reports = recordValue(operations.management_reports);
	const roosterLevel = Math.max(0, Math.trunc(numberValue(operations.rooster_office_level, 0)));
	const itLevel = Math.max(0, Math.trunc(numberValue(operations.it_coop_level, 0)));
	const actionLimit = Math.max(1, Math.trunc(numberValue(supervision.action_limit, 1)));
	const actionsUsed = Math.max(0, Math.min(actionLimit, Math.trunc(numberValue(supervision.actions_used, 0))));
	const actionsRemaining = Math.max(0, Math.min(actionLimit, Math.trunc(numberValue(
		supervision.actions_remaining,
		actionLimit - actionsUsed,
	))));
	const supervisorPayroll = Math.max(0, Math.trunc(numberValue(supervision.supervisor_payroll_cents, 0)));
	const grievance = Math.max(0, numberValue(supervision.surveillance_grievance_millipoints, 0) / 1_000);
	const stress = Math.max(0, numberValue(supervision.surveillance_stress_millipoints, 0) / 1_000);
	const solidarity = Math.max(0, numberValue(supervision.surveillance_solidarity_millipoints, 0) / 1_000);
	const supervisionPressure = grievance + stress + solidarity > 0
		? ` Surveillance adds ${formatPointValue(grievance)} grievance and ${formatPointValue(stress)} stress per hen, plus ${formatPointValue(solidarity)} flock solidarity per shift.`
		: " Surveillance pressure is inactive.";

	const automationEnabled = automation.enabled === true && itLevel > 0;
	const workPercent = Math.max(0, (numberValue(automation.work_basis_points, 10_000) - 10_000) / 100);
	const specialtyGrace = Math.max(0, Math.trunc(numberValue(automation.specialty_grace_minutes, 180)));
	const secondary = automation.recognizes_secondary_specialties === true;
	const complianceExposure = Math.max(0, numberValue(automation.compliance_exposure_millipoints, 0) / 1_000);
	const ledgerPatch = Math.max(0, Math.trunc(numberValue(automation.ledger_patch_cost_cents, 0)));
	const automationSummary = automationEnabled
		? `IT Coop level ${itLevel}: AUTO pace ${formatPercent(workPercent)}, ${specialtyGrace}-minute specialty grace, ${secondary ? "secondary credentials recognized" : "primary credential only"}; compliance exposure ${formatPointValue(complianceExposure)} per shift and ledger patch ${formatCurrencyFromCents(ledgerPatch)}.`
		: `IT Coop level ${itLevel}: AUTO remains local at base pace with ${specialtyGrace}-minute specialty grace.`;
	const rosterRows = roster.map((manager, index) => {
		const name = diagnosticPlainText(stringValue(manager.name), 60) || `Manager ${index + 1}`;
		const title = diagnosticPlainText(stringValue(manager.title), 60) || "Acting Lead";
		const assignment = diagnosticPlainText(stringValue(manager.assignment_label), 60) || "whole flock";
		const posture = manager.posture_filed === true
			? diagnosticPlainText(stringValue(manager.posture_label), 60) || "filed posture"
			: "posture not yet filed";
		return `${name}, ${title}, assigned ${assignment}, ${posture}`;
	});
	const managerCount = Math.max(rosterRows.length, Math.trunc(numberValue(density.manager_count, rosterRows.length)));
	const activeHens = Math.max(0, Math.trunc(numberValue(density.active_hens, 0)));
	const meetingMinutes = Math.max(0, Math.trunc(numberValue(density.meeting_minutes, 0)));
	const conflicts = Math.max(0, Math.trunc(numberValue(density.conflicting_directives, 0)));
	const riskLabel = diagnosticPlainText(stringValue(density.risk_label), 40).toLowerCase() || "workable";
	const reportsToday = Math.max(0, Math.trunc(numberValue(reports.today, 0)));
	const candidateCount = Array.isArray(operations.manager_candidates)
		? operations.manager_candidates.filter((candidate) => recordValue(candidate).hired !== true).length
		: 0;
	const managerSummary = rosterRows.length > 0
		? ` Management roster: ${rosterRows.join("; ")}. Density ${managerCount} managers for ${activeHens} hens, ${meetingMinutes} meeting minutes, ${conflicts} conflicting directives, ${riskLabel}. ${reportsToday} management ${reportsToday === 1 ? "report" : "reports"} filed today; management reports produce zero eggs. Successor slate: ${candidateCount} non-incumbent ${candidateCount === 1 ? "candidate" : "candidates"}.`
		: "";
	return `Rooster Operations Office level ${roosterLevel}: ${actionsUsed} of ${actionLimit} check-ins used, ${actionsRemaining} remaining; supervisor payroll ${formatCurrencyFromCents(supervisorPayroll)} per day.${supervisionPressure} ${automationSummary}${managerSummary}`;
}

function operationsActivitySummary(operations: GameDiagnostic): string {
	if (Object.keys(operations).length === 0) return "";
	const supervision = recordValue(operations.supervision);
	const automation = recordValue(operations.automation);
	const density = recordValue(operations.management_density);
	const reports = recordValue(operations.management_reports);
	const actionLimit = Math.max(1, Math.trunc(numberValue(supervision.action_limit, 1)));
	const actionsUsed = Math.max(0, Math.min(actionLimit, Math.trunc(numberValue(supervision.actions_used, 0))));
	const actionsRemaining = Math.max(0, Math.min(actionLimit, Math.trunc(numberValue(
		supervision.actions_remaining,
		actionLimit - actionsUsed,
	))));
	const autoHens = Math.max(0, Math.trunc(numberValue(automation.auto_enrolled_workers, 0)));
	const autoClaims = Math.max(0, Math.trunc(numberValue(automation.active_auto_claims, 0)));
	const automationActive = automation.enabled === true;
	const autoSummary = automationActive
		? ` IT Coop supports ${autoHens} AUTO ${autoHens === 1 ? "hen" : "hens"}, ${autoClaims} with active ${autoClaims === 1 ? "file" : "files"}.`
		: "";
	const managerCount = Math.max(0, Math.trunc(numberValue(density.manager_count, 0)));
	const activeHens = Math.max(0, Math.trunc(numberValue(density.active_hens, 0)));
	const meetingMinutes = Math.max(0, Math.trunc(numberValue(density.meeting_minutes, 0)));
	const conflicts = Math.max(0, Math.trunc(numberValue(density.conflicting_directives, 0)));
	const reportsToday = Math.max(0, Math.trunc(numberValue(reports.today, 0)));
	const managerSummary = managerCount > 0
		? ` Management layer: ${managerCount} managers for ${activeHens} hens, ${meetingMinutes} meeting minutes, ${conflicts} conflicting directives, ${reportsToday} ${reportsToday === 1 ? "report" : "reports"}, zero eggs.`
		: "";
	return `Rooster Operations: ${actionsUsed} of ${actionLimit} check-ins filed, ${actionsRemaining} remaining.${autoSummary}${managerSummary}`;
}

function nextOperationsActionSummary(operations: GameDiagnostic): string {
	const action = recordValue(operations.next_operations_action);
	if (Object.keys(action).length === 0) return "";
	if (action.complete === true) return "Operations campus fully commissioned.";
	const facilityId = stringValue(action.facility_id) || stringValue(action.id) || "operations expansion";
	const levelName = stringValue(action.next_level_name)
		|| stringValue(action.display_name)
		|| facilityId.replaceAll("_", " ");
	const nextLevel = Math.max(1, Math.trunc(numberValue(action.next_level, numberValue(action.level, 1))));
	const capital = Math.max(0, Math.trunc(numberValue(
		action.cost_cents,
		numberValue(action.capital_cost_cents, numberValue(action.next_level_cost_cents, 0)),
	)));
	const dailyCost = Math.trunc(numberValue(
		action.added_daily_operating_cents,
		numberValue(action.maintenance_delta_cents, 0) + numberValue(action.supervisor_payroll_delta_cents, 0),
	));
	const ready = action.can_purchase === true || action.available === true;
	const reason = stringValue(action.reason).replace(/\s+/g, " ").trim();
	const reasonSummary = !ready && reason.length > 0 ? ` Gate: ${reason}` : "";
	return `Next operations ${ready ? "file" : "gate"}: ${levelName}, level ${nextLevel}, ${formatCurrencyFromCents(capital)} capital and ${formatSignedCurrencyFromCents(dailyCost)} daily operating cost.${reasonSummary}`;
}

function formatPointValue(value: number): string {
	const points = Math.round(Math.max(0, value) * 100) / 100;
	const amount = Number.isInteger(points) ? points.toFixed(0) : points.toFixed(2).replace(/0$/, "");
	return `${amount} ${points === 1 ? "point" : "points"}`;
}

function trainingWorkPenaltyPercent(trainingTerms: GameDiagnostic): number {
	if (typeof trainingTerms.work_penalty_percent === "number") {
		return Math.max(0, trainingTerms.work_penalty_percent);
	}
	const basisPoints = numberValue(trainingTerms.pending_work_basis_points, Number.NaN);
	const multiplier = Number.isFinite(basisPoints)
		? basisPoints / 10_000
		: numberValue(
			trainingTerms.effective_work_multiplier,
			numberValue(trainingTerms.pending_work_multiplier, 0.85),
		);
	return Math.max(0, Math.round((1 - multiplier) * 1_000) / 10);
}

function formatPlainPercent(value: number): string {
	const percent = Math.round(Math.max(0, value) * 10) / 10;
	return `${Number.isInteger(percent) ? percent.toFixed(0) : percent.toFixed(1)} percent`;
}

function isRestedFlockTerms(contract: GameDiagnostic): boolean {
	const clause = recordValue(contract.clause);
	const clauseId = stringValue(contract.clause_id) || stringValue(clause.id);
	return clauseId === "rested_flock_rider"
		|| clauseId === "rested_flock_warranty"
		|| ["rested_flock_rider", "rested_flock_warranty"].includes(stringValue(contract.rider_id))
		|| numberValue(contract.welfare_minimum, numberValue(contract.welfare_gate, 0)) > 0;
}

function parseGameDiagnostic(renderedState: string | undefined): GameDiagnostic {
  if (!renderedState) return {};
  try {
    return recordValue(JSON.parse(renderedState) as unknown);
  } catch {
    return {};
  }
}

function recordValue(value: unknown): GameDiagnostic {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? value as GameDiagnostic
    : {};
}

function diagnosticRecordCollection(value: unknown): GameDiagnostic[] {
	if (Array.isArray(value)) {
		return value
			.map(recordValue)
			.filter((record) => Object.keys(record).length > 0);
	}
	const source = recordValue(value);
	if (Object.keys(source).length === 0) return [];
	if (hasDiagnosticKey(source, "id") || hasDiagnosticKey(source, "module_id") || hasDiagnosticKey(source, "parcel_id")) {
		return [source];
	}
	return Object.entries(source)
		.map(([id, entry]) => {
			const record = recordValue(entry);
			return Object.keys(record).length > 0
				? { id, ...record }
				: {};
		})
		.filter((record) => Object.keys(record).length > 0);
}

function diagnosticAssignmentCollection(value: unknown): GameDiagnostic[] {
	if (Array.isArray(value)) return diagnosticRecordCollection(value);
	const source = recordValue(value);
	return Object.entries(source).map(([moduleId, entry]) => {
		const record = recordValue(entry);
		if (Object.keys(record).length > 0) return { module_id: moduleId, ...record };
		return { module_id: moduleId, worker_id: entry };
	});
}

function diagnosticRecordName(record: GameDiagnostic, fallbackId: string): string {
	const authored = stringValue(record.name)
		|| stringValue(record.display_name)
		|| stringValue(record.short_name);
	if (authored.length === 0) return diagnosticTitle(fallbackId);
	return authored === authored.toUpperCase()
		? diagnosticTitle(authored.toLowerCase().replace(/\s+/g, "_"))
		: authored;
}

function diagnosticTitle(value: string): string {
	return value
		.replaceAll("_", " ")
		.trim()
		.split(/\s+/)
		.filter(Boolean)
		.map((word) => `${word.charAt(0).toUpperCase()}${word.slice(1).toLowerCase()}`)
		.join(" ");
}

function joinDiagnosticList(values: string[]): string {
	if (values.length === 0) return "none";
	if (values.length === 1) return values[0];
	if (values.length === 2) return `${values[0]} and ${values[1]}`;
	return `${values.slice(0, -1).join(", ")}, and ${values.at(-1)}`;
}

function hasDiagnosticKey(record: GameDiagnostic, key: string): boolean {
	return Object.prototype.hasOwnProperty.call(record, key);
}

function stringValue(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function numberValue(value: unknown, fallback: number): number {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

function formatCurrencyFromCents(value: number): string {
  const cents = Math.max(0, Math.trunc(value));
  return `$${(cents / 100).toFixed(2)}`;
}

function formatSignedCurrencyFromCents(value: number): string {
  const cents = Math.trunc(value);
  const sign = cents >= 0 ? "+" : "-";
  return `${sign}$${(Math.abs(cents) / 100).toFixed(2)}`;
}

function formatPercent(value: number): string {
  const percent = Math.round(Math.max(0, value) * 10) / 10;
  return `+${Number.isInteger(percent) ? percent.toFixed(0) : percent.toFixed(1)} percent`;
}

function contractPremiumSummary(activeContract: GameDiagnostic): string {
  const totalCents = Math.max(0, Math.trunc(numberValue(activeContract.premium_cents, 0)));
  const baseCents = Math.max(0, Math.trunc(numberValue(
    activeContract.authored_base_premium_cents,
    numberValue(activeContract.base_premium_cents, totalCents),
  )));
  const seasonDeltaCents = Math.trunc(numberValue(
    activeContract.season_premium_delta_cents,
    0,
  ));
  const clauseDeltaCents = Math.trunc(numberValue(
    activeContract.clause_premium_delta_cents,
    0,
  ));
  const serviceCoopBonusCents = Math.max(0, Math.trunc(numberValue(
    activeContract.service_coop_bonus_cents,
    Math.max(0, totalCents - baseCents - seasonDeltaCents - clauseDeltaCents),
  )));
  if (seasonDeltaCents === 0 && clauseDeltaCents === 0) {
    return `base premium ${formatCurrencyFromCents(baseCents)}, Service Coop bonus ${formatCurrencyFromCents(serviceCoopBonusCents)}, total ${formatCurrencyFromCents(totalCents)}`;
  }
  return `authored premium ${formatCurrencyFromCents(baseCents)}, season ${formatSignedCurrencyFromCents(seasonDeltaCents)}, rider ${formatSignedCurrencyFromCents(clauseDeltaCents)}, Service Coop bonus ${formatCurrencyFromCents(serviceCoopBonusCents)}, total ${formatCurrencyFromCents(totalCents)}`;
}

function contractClauseSummary(contract: GameDiagnostic): string {
  const clause = recordValue(contract.clause);
  const clauseId = stringValue(contract.clause_id) || stringValue(clause.id);
  const clauseLabel = stringValue(contract.clause_label)
    || stringValue(clause.label)
    || stringValue(clause.name);
  if (clauseLabel.length > 0) return clauseLabel;
  if (clauseId.length > 0 && clauseId !== "standard_terms") {
    return clauseId.replaceAll("_", " ");
  }
  return "Standard Terms";
}

function activeContractObjective(
  activeContract: GameDiagnostic,
  completed: number,
  required: number,
): string {
  if (completed >= required) {
    return "protect the regular clutch until close; the binder threshold is met and its premium will settle then.";
  }

  const completedClaimIds = new Set(
    Array.isArray(activeContract.completed_claim_ids)
      ? activeContract.completed_claim_ids
      : [],
  );
  let nextDue: { minute: number; time: string } | undefined;
  let nextArrival: { minute: number; time: string } | undefined;
  const scheduledClaims = Array.isArray(activeContract.scheduled_claims)
    ? activeContract.scheduled_claims
    : [];

  for (const candidate of scheduledClaims) {
    const schedule = recordValue(candidate);
    if (schedule.rejected === true) continue;
    const claimId = schedule.claim_id;
    if (schedule.released === true && !completedClaimIds.has(claimId)) {
      const minute = Math.trunc(numberValue(schedule.deadline_minute_of_day, Number.MAX_SAFE_INTEGER));
      if (!nextDue || minute < nextDue.minute) {
        nextDue = {
          minute,
          time: stringValue(schedule.deadline_time) || formatOfficeMinute(minute),
        };
      }
    } else if (schedule.released !== true) {
      const minute = Math.trunc(numberValue(schedule.arrival_minute_of_day, Number.MAX_SAFE_INTEGER));
      if (!nextArrival || minute < nextArrival.minute) {
        nextArrival = {
          minute,
          time: stringValue(schedule.arrival_time) || formatOfficeMinute(minute),
        };
      }
    }
  }

  if (nextDue) {
    return `clear the released Farm Mutual folder due at ${nextDue.time}, then protect the regular clutch.`;
  }
  if (nextArrival) {
    return `route the regular clutch now and leave capacity for the next Farm Mutual batch at ${nextArrival.time}.`;
  }
  return "protect the regular clutch and review the binder shortfall; no further Farm Mutual arrivals remain.";
}

function formatOfficeMinute(value: number): string {
  if (!Number.isFinite(value) || value < 0) return "the disclosed time";
  const minuteOfDay = Math.trunc(value) % (24 * 60);
  const hour24 = Math.trunc(minuteOfDay / 60);
  const minute = minuteOfDay % 60;
  const suffix = hour24 >= 12 ? "PM" : "AM";
  const hour12 = hour24 % 12 || 12;
  return `${hour12}:${minute.toString().padStart(2, "0")} ${suffix}`;
}

function firstClutchObjective(stage: string): string {
  switch (stage) {
    case "inspect":
      return "inspect a hen and read her dossier.";
    case "specialty_route":
      return "route the selected hen to her specialty lane.";
    case "check_in":
      return "file one personnel check-in.";
    case "priority_peck":
      return "land a Priority Peck in the gold window.";
    case "delivery":
      return "follow the assisted egg through grading and collection.";
    case "complete":
      return "open Flockwatch and review today's orders.";
    default:
      return "follow the highlighted First Clutch step.";
  }
}

function campaignHasBegun(state: GameDiagnostic): boolean {
	const campaignStage = typeof state.campaign_stage === "string"
		? state.campaign_stage.trim().toLowerCase()
		: "";
	return campaignStage.length > 0 && campaignStage !== "title";
}

function loadingStageText(progress: number): string {
	if (progress >= 100) return "Assembling the opening office...";
	if (progress > 0) return `Loading office runtime and assets... ${Math.round(progress)}%`;
	return "Preparing the browser runtime...";
}

function loadGodotScript(): Promise<void> {
  if (document.querySelector('script[data-godot-runtime="true"]')) return Promise.resolve();
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = "/game/index.js";
    script.dataset.godotRuntime = "true";
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("Unable to load the browser game runtime."));
    document.head.appendChild(script);
  });
}

async function loadGodotConfig(): Promise<Record<string, unknown>> {
  const shell = await fetch("/game/index.html").then((response) => {
    if (!response.ok) throw new Error("Unable to read the exported game manifest.");
    return response.text();
  });
  const match = shell.match(/const GODOT_CONFIG = (\{.*\});/);
  if (!match) throw new Error("The exported game manifest is invalid.");

  const config = JSON.parse(match[1]) as Record<string, unknown>;
  const executable = String(config.executable ?? "index");
  const fileSizes = (config.fileSizes ?? {}) as Record<string, number>;
  config.executable = `/game/${executable}`;
  config.fileSizes = Object.fromEntries(
    Object.entries(fileSizes).map(([path, size]) => [`/game/${path}`, size]),
  );
  return config;
}
