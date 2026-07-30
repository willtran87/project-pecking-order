class_name CharacterDialogueLibrary
extends RefCounted

## Authored voice library for the recurring Pecking Order cast.
##
## This file owns voice, role, portrait, and reusable thematic lines. The
## catalogue decides *when* a line is eligible from authoritative simulation
## state; keeping the copy here makes adding variety safe without touching the
## economy or inventing parallel character statistics.

const SPEAKERS := {
	&"mabel": {
		"name": "Mabel",
		"role": "APPEALS  /  BRIGHT-EYED",
		"portrait": &"mabel",
		"channel": &"PRIVATE ASIDE",
	},
	&"pip": {
		"name": "Pip",
		"role": "NEST DAMAGE  /  QUIET PROFESSIONAL",
		"portrait": &"pip",
		"channel": &"PRIVATE ASIDE",
	},
	&"henrietta": {
		"name": "Henrietta",
		"role": "PREDATOR LOSS  /  COZY NESTER",
		"portrait": &"henrietta",
		"channel": &"FLOOR CHAT",
	},
	&"dot": {
		"name": "Dot",
		"role": "NEST DAMAGE  /  PERCH-SIDE NETWORKER",
		"portrait": &"dot",
		"channel": &"BREAK-ROOM WHISPER",
	},
	&"agnes": {
		"name": "Agnes",
		"role": "APPEALS  /  METHODICAL PECKER",
		"portrait": &"agnes",
		"channel": &"FILE NOTE",
	},
	&"beatrice": {
		"name": "Beatrice",
		"role": "PREDATOR LOSS  /  GENTLE REBEL",
		"portrait": &"beatrice",
		"channel": &"QUIET ASIDE",
	},
	&"cornelius": {
		"name": "Cornelius Claimwell",
		"role": "CREDIT MANAGER  /  ACTING LEAD",
		"portrait": &"cornelius",
		"channel": &"MANAGEMENT ASIDE",
	},
	&"bramwell": {
		"name": "Bramwell Beakley",
		"role": "QUOTA MANAGER  /  STRETCH CLUTCH",
		"portrait": &"bramwell",
		"channel": &"MANAGEMENT ASIDE",
	},
	&"prudence": {
		"name": "Prudence Peckworth",
		"role": "COMPLIANCE MANAGER  /  AUDIT LEAD",
		"portrait": &"prudence",
		"channel": &"CONTROL NOTE",
	},
	&"clover": {
		"name": "Clover Crowsby",
		"role": "CULTURE MANAGER  /  MORALE LEAD",
		"portrait": &"clover",
		"channel": &"CULTURE ASIDE",
	},
	&"pivot": {
		"name": "Pivot Strutters",
		"role": "REORG MANAGER  /  CHANGE OFFICE",
		"portrait": &"pivot",
		"channel": &"TRANSFORMATION NOTE",
	},
	&"byte": {
		"name": "Byte Bantam",
		"role": "AUTOMATION MANAGER  /  IT COOP",
		"portrait": &"byte",
		"channel": &"SYSTEM ASIDE",
	},
	&"intern_lottie": {
		"name": "Lottie Ledger",
		"role": "APPEALS INTERN  /  EAGER VERIFIER",
		"portrait": &"intern_lottie",
		"channel": &"INTERN CHECK-IN",
	},
	&"intern_chip": {
		"name": "Chip Chirper",
		"role": "OPERATIONS INTERN  /  SOCIAL OPTIMIST",
		"portrait": &"intern_chip",
		"channel": &"INTERN CHECK-IN",
	},
	&"intern_marigold": {
		"name": "Marigold Memo",
		"role": "CLAIMANT CARE INTERN  /  PURPOSE HELPER",
		"portrait": &"intern_marigold",
		"channel": &"INTERN CHECK-IN",
	},
	&"intern_tilly": {
		"name": "Tilly Tabs",
		"role": "SYSTEMS INTERN  /  FAST LEARNER",
		"portrait": &"intern_tilly",
		"channel": &"INTERN CHECK-IN",
	},
}

const WORKER_SPEAKERS: Array[StringName] = [
	&"mabel", &"pip", &"henrietta", &"dot", &"agnes", &"beatrice",
]

const MANAGER_SPEAKER_BY_CANDIDATE := {
	&"cornelius_credit": &"cornelius",
	&"bramwell_quota": &"bramwell",
	&"prudence_compliance": &"prudence",
	&"clover_culture": &"clover",
	&"pivot_reorg": &"pivot",
	&"byte_automation": &"byte",
}

const INTERN_SPEAKER_BY_CANDIDATE := {
	&"lottie_ledger": &"intern_lottie",
	&"chip_chirper": &"intern_chip",
	&"marigold_memo": &"intern_marigold",
	&"tilly_tabs": &"intern_tilly",
}

const VOICE_POOLS := {
	&"mabel": {
		&"production": [
			"I closed another file. The basket is already practicing the farmer's signature.",
			"The claim is finished. Credit is now traveling upstairs without me.",
			"The screen says complete. My name remains an optional field.",
			"I made the number move. Management will explain what inspired it.",
			"Another clean egg. Somewhere, a slide deck has become more confident.",
		],
		&"pressure": [
			"I can keep up. I just need the claims to stop arriving while I do it.",
			"The queue is learning faster than I can peck.",
			"My file is current. I am several versions behind.",
			"I asked which task was urgent. The answer was yes.",
		],
		&"review": [
			"The shift is over. The interpretation phase has begun.",
			"We did the work. Now we wait to learn what management accomplished.",
			"The basket is full enough to become a leadership story.",
		],
	},
	&"pip": {
		&"production": [
			"The dashboard moved. I have recorded that it happened without celebrating prematurely.",
			"Another file cleared. I will now quietly prevent the next one from becoming interesting.",
			"The work is complete. I have left the process exactly one backup.",
			"I fixed the exception. The official workflow remains unaware it had one.",
		],
		&"pressure": [
			"The dashboard is green. I have learned this is unrelated to how anyone feels.",
			"I am not behind. The deadline has simply moved into my chair.",
			"Everything is under control, provided nobody asks the control.",
			"The queue is stable in the sense that it is consistently too large.",
		],
		&"review": [
			"The totals reconcile. The feelings remain outside ledger scope.",
			"We survived another shift with no unauthorized honesty.",
			"I saved the file twice. Management has saved the phrase lessons learned.",
		],
	},
	&"henrietta": {
		&"production": [
			"That shell held. I would like the same standard applied to the flock.",
			"Another file cleared. The quiet nest remains a future-state benefit.",
			"The egg is sound. Please do not call the hen resilient until after feed.",
			"I finished before the cushion request completed review.",
		],
		&"pressure": [
			"My nest pad is ergonomic. The workload remains shaped like the old one.",
			"The care policy is very supportive when printed in color.",
			"I scheduled a recovery minute. Operations counteroffered with a file.",
			"The office is warm enough for the equipment.",
		],
		&"review": [
			"The shift ended. My shoulders have requested a separate closing report.",
			"We made quota. Wellness will celebrate after approving the appointment.",
			"The flock is tired in a way the scorecard has classified as temporary.",
		],
	},
	&"dot": {
		&"production": [
			"Another file cleared. I know because three departments have claimed to unblock it.",
			"The floor is moving. Management has scheduled a meeting to identify who authorized motion.",
			"That egg has already been mentioned in two conversations it did not attend.",
			"The queue got shorter. Please enjoy this before Intake notices.",
		],
		&"pressure": [
			"Everyone is fine. I checked individually, so nobody had to say it in front of management.",
			"The floor agrees the floor is calm. The floor asked me not to cite names.",
			"Morale is holding a private meeting without Culture.",
			"Half the flock needs a break. The other half is covering the first half.",
		],
		&"review": [
			"The shift is closed. Informal attribution remains extremely open.",
			"I heard the farmer liked the numbers. The numbers declined comment.",
			"Tomorrow's rumor is that today went according to plan.",
		],
	},
	&"agnes": {
		&"hire": [
			"I found the vacant perch, the appeals queue, and the clause saying only one of them is temporary.",
			"My onboarding packet says independent judgment. The routing policy says auto.",
			"I have reviewed the job description. It appears to be an aspirational document.",
		],
		&"production": [
			"The exclusion was buried on page six. The farmer's name was on page one.",
			"I reconciled the file. Management had already reconciled itself with the error.",
			"The appeal is valid. I expect this to become a tone issue.",
			"I checked the total twice. The second check was not more popular.",
			"The numbers agree with me. We are both awaiting authorization.",
		],
		&"pressure": [
			"I have prioritized every priority. The result is mathematically familiar.",
			"The queue exceeds capacity by exactly the amount nobody wants documented.",
			"I can work faster or check the work. The policy has selected both.",
			"My visor reduces glare. It has not reduced expectations.",
		],
		&"review": [
			"The totals are correct. This is now the least convenient part of the report.",
			"I closed the books. Someone reopened the narrative.",
			"The variance has a cause. The cause has requested a softer label.",
		],
	},
	&"beatrice": {
		&"hire": [
			"They called this a fresh opportunity. The chair still has an exit interview on it.",
			"I am happy to join the flock. I have also read the flock's grievance history.",
			"The welcome packet says speak freely. The lanyard opens only approved doors.",
		],
		&"production": [
			"The claimant was frightened. The file was marked routine. I corrected one of those things.",
			"Another predator file closed. The predator remains outside our reporting boundary.",
			"I finished the case without converting concern into a metric.",
			"The shell held because the flock did, not because the poster asked nicely.",
			"I signed the file. I did not sign away the memory.",
		],
		&"pressure": [
			"I am agreeable. That is not the same as agreeing.",
			"The flock can stretch. It is the returning to shape that concerns me.",
			"I have remained calm long enough to make management suspicious.",
			"The queue is temporary. So, apparently, is every boundary.",
		],
		&"review": [
			"We made it through. I would prefer that not become the new baseline.",
			"The report calls us aligned. We were standing close together for warmth.",
			"I have no complaint for the record. The record already has several.",
		],
	},
	&"cornelius": {
		&"appointment": [
			"They moved me up to management. The vent is stronger up here. The farmer reads the same numbers to me, only colder.",
			"I have a title, a clipboard, and no authority over the thermostat.",
			"The farmer says I own the outcome. Payroll says I rent the chair.",
		],
		&"management": [
			"I did not lay the egg. I did attend the meeting where we renamed it an outcome.",
			"I understand the flock's concern. I have placed it beneath the quota where it will be safe.",
			"The farmer wants certainty. I have asked the chart to look more certain.",
			"I am not above the flock. My perch is simply colder and itemized.",
		],
		&"review": [
			"The farmer will ask why. I have prepared a slide showing when.",
			"The result is mixed, which means the presentation requires stronger headings.",
			"Management accepts full responsibility for describing what happened.",
		],
	},
	&"bramwell": {
		&"appointment": [
			"I brought a stretch target and enough enthusiasm to classify concern as resistance.",
			"The newest management post is mine. I have already raised its expectations.",
			"I do not believe in impossible quotas. I believe in insufficiently aligned calendars.",
		],
		&"management": [
			"Every clutch can stretch. The shells have asked me to stop using that phrase.",
			"We are one heroic effort away from making heroic effort the baseline.",
			"The number is ambitious because the flock has not achieved it yet.",
			"I canceled lunch to create capacity. Finance has recognized the savings.",
		],
		&"review": [
			"We missed the stretch target but exceeded the explanation target.",
			"Quota is not pressure. It is a number standing very close behind you.",
			"The clutch grew. Tomorrow, its expectation will remember.",
		],
	},
	&"prudence": {
		&"appointment": [
			"I have accepted the post provisionally, pending documentation that I accepted the post.",
			"The control environment is now supervised. The actual environment remains out of scope.",
			"I found six exceptions during onboarding. Five were onboarding.",
		],
		&"management": [
			"If it is not filed, it did not happen. If it is filed incorrectly, it happened twice.",
			"The flock may proceed after demonstrating it already complied.",
			"I do not create paperwork. I reveal paperwork that was always required.",
			"The rule is clear. Its purpose is currently under document hold.",
		],
		&"review": [
			"The totals pass. I remain concerned by their informal confidence.",
			"The shift closed with no unrecorded incidents we recorded.",
			"Compliance is satisfied. I have scheduled a review of that satisfaction.",
		],
	},
	&"clover": {
		&"appointment": [
			"I am delighted to lead Culture. Attendance at that delight begins tomorrow.",
			"My door is always open during the hours listed in the closed-door policy.",
			"The flock deserves warmth. I have prepared a mandatory circle about it.",
		],
		&"management": [
			"Morale cannot be forced. Participation in morale can.",
			"I brought feed and a listening form. Please rank which helped.",
			"We are a family, specifically the kind with quarterly calibration.",
			"The flock asked for rest. I have approved a gratitude exercise.",
		],
		&"review": [
			"Today was difficult, so tomorrow's theme is sustainable enthusiasm.",
			"The sentiment score improved after we clarified the scoring audience.",
			"Everyone contributed. Some contributions were quieter than policy recommends.",
		],
	},
	&"pivot": {
		&"appointment": [
			"I have joined to reduce disruption through a complete reorganization.",
			"The old chart had too many boxes. The new chart has arrows.",
			"I am not replacing anyone. I am redefining where they used to be.",
		],
		&"management": [
			"Motion is not progress, but it photographs extremely well.",
			"Your role is unchanged except for its name, owner, route, and chair.",
			"The flock requested clarity. I have color-coded the uncertainty.",
			"We found no new capacity, so I moved the capacity box higher.",
		],
		&"review": [
			"The transition succeeded. Operations will resume after the next transition.",
			"We learned a great deal, primarily where the boxes fit.",
			"The new structure preserved every old problem under a stronger heading.",
		],
	},
	&"byte": {
		&"appointment": [
			"I have connected the spreadsheet to the coop. The coop has not consented to the integration.",
			"The newest management post is now automated enough to require me full time.",
			"I replaced three manual checks with one dashboard and seven alerts.",
		],
		&"management": [
			"The model is neutral. The assumptions have requested privacy.",
			"Automation removed the repetitive work and generated repetitive exception handling.",
			"The dashboard sees every hen equally, at the wrong resolution.",
			"I patched the workflow. Please avoid asking which workflow.",
		],
		&"review": [
			"The system performed perfectly after excluding the minutes when it did not.",
			"Throughput improved. Human-readable causality is scheduled for version two.",
			"The automation saved time. I have spent it reconciling the automation.",
		],
	},
	&"intern_lottie": {
		&"onboard": [
			"The credential packet costs less than training a new hire, so I already saved the team money!",
			"They trusted me with live appeals on my first day. I must have made a very strong unpaid impression.",
			"My badge says intern, but the files say urgent. I love that the work does not see titles!",
		],
		&"guided_shadow": [
			"I get to check the real files while everyone else signs them. That means I am learning accountability!",
			"My mentor said to watch closely, then left me the queue. I think this is immersive training.",
			"I found three errors and fixed them quietly. It feels good to protect the team's confidence.",
		],
		&"stretch_project": [
			"Corporate says if I do well on this task, they will give me more. It is nice to have a clear growth path!",
			"The stretch project is outside my role, which means I am already growing beyond my role!",
			"I am responsible for the deadline but not authorized to change it. That is excellent practice for leadership.",
		],
		&"culture_sprint": [
			"I made a gratitude tracker for the hens covering vacancies. Now their extra work will be visible!",
			"Culture asked me to collect anonymous feedback and attach everyone’s department. I am learning so much about trust.",
			"I get to organize morale between my regular files. It is wonderful that enthusiasm fits anywhere.",
		],
		&"term_complete": [
			"My review says I exceeded the internship scope. I hope that means the scope noticed me!",
			"I completed every objective, including the ones added after I completed every objective!",
			"Three shifts already! They said the decision is about future opportunity, so it must be a good kind of waiting.",
		],
		&"growth_extension": [
			"They extended my growth period! I get two more shifts to prove the same thing with newer evidence.",
			"My title is unchanged because they do not want labels to limit my potential.",
			"The meal card increased by a whole dollar. It is exciting when compensation becomes measurable.",
		],
		&"recommendation_letter": [
			"My recommendation says I performed at employee level. Future employers are going to love that sentence!",
			"They could not offer a perch, but they offered adjectives. I received three of the strongest ones.",
		],
		&"paid_fellowship": [
			"My badge finally says paid! Everyone cheered, especially the part of me that buys feed.",
			"I have a real junior post now. Apparently the work was real first and the post needed more review.",
		],
	},
	&"intern_chip": {
		&"onboard": [
			"Leadership said this rotation is all about exposure. I have already been exposed to four calendars!",
			"I am sitting near the managers, which is basically mentorship with a wider audio range.",
			"They gave me a blank badge so I can define my own brand. Security calls it temporary access.",
		],
		&"guided_shadow": [
			"I get to join every status meeting and send every recap. My name is in so many sent folders!",
			"My mentor says the best networking happens while carrying someone else's chart.",
			"I am shadowing Operations. Operations moves fast, so mostly I am carrying its notes.",
		],
		&"stretch_project": [
			"I own a leadership deliverable! Leadership still owns the successful version, which feels collaborative.",
			"They said this project has high visibility. I can already see everyone who will ask me for updates.",
			"If I finish early, I get invited to the next stretch project. Momentum is such a generous reward.",
		],
		&"culture_sprint": [
			"I scheduled an optional enthusiasm breakfast at 7:15. Every leader accepted on behalf of their team!",
			"I am mapping the office network. So far every arrow points toward someone with less time.",
			"Culture gave me the employee-recognition list. I get to remove anyone whose manager forgot the form.",
		],
		&"term_complete": [
			"My review had six managers in it. That is more executive exposure than some full-time hens get!",
			"They said I am unforgettable, then asked me to spell my name for the certificate.",
			"The rotation ended, but my networking tasks continue informally. I am already building continuity.",
		],
		&"growth_extension": [
			"I have been invited back without restarting onboarding. That is practically seniority!",
			"The extension means they see long-term potential, specifically two shifts long.",
			"They kept my calendar access active. Relationships really are the best compensation.",
		],
		&"recommendation_letter": [
			"My letter says I work well with senior stakeholders. I wrote that line, so I know it is accurate.",
			"I am leaving with twelve new contacts and eleven requests to stay in touch when they need notes.",
		],
		&"paid_fellowship": [
			"I got the fellowship! Networking works, especially after the network runs out of free scheduling support.",
			"I have a paid seat near leadership now. The chair is the same, but Payroll can see it.",
		],
	},
	&"intern_marigold": {
		&"onboard": [
			"They said the flock needs helpers who care more than they count hours. That sounds exactly like me!",
			"I get to support claimants and cover two vacant functions. Purpose can be very cross-functional.",
			"The welcome packet says bring your whole self. I also brought lunch in case the whole self stays late.",
		],
		&"guided_shadow": [
			"I listen to claimants while the hens clear files. It is nice that emotional labor has no queue limit.",
			"My mentor trusts me to handle the difficult conversations she no longer has time to attend.",
			"I am learning how care becomes a form, then a checkbox, then a completed objective.",
		],
		&"stretch_project": [
			"They gave me ownership because the position is still unfilled. I am getting the full job experience!",
			"I am covering Intake and Care today. It is wonderful when departments collaborate inside one intern.",
			"The project matters too much to wait for staffing. I am proud my availability solved the business case.",
		],
		&"culture_sprint": [
			"I asked what the flock needs. Culture asked me to fit the answers on one cheerful page.",
			"I am running the listening circle during lunch so nobody has to lose productive time.",
			"The hens said they need rest. I turned that into a theme for next month's wellness board!",
		],
		&"term_complete": [
			"They said I made an employee-sized difference. I cannot wait to hear what size opportunity that earns.",
			"My term is complete, but the claimants still have my number. Continuity feels very meaningful.",
			"I covered every gap they showed me. The review says my greatest strength is flexibility.",
		],
		&"growth_extension": [
			"I get two more shifts to deepen my impact. The vacancies are also deepening, so the timing is perfect.",
			"They extended the rotation instead of replacing the missing roles. I must be helping the budget too!",
			"My meal card was renewed. It feels good when care comes back around in exact dollar amounts.",
		],
		&"recommendation_letter": [
			"The letter says I gave more than expected. I hope the next office expects the correct amount.",
			"They thanked me for serving the mission. The mission is keeping my contact details.",
		],
		&"paid_fellowship": [
			"They made the work a paid fellowship! I am glad the work and the pay finally met.",
			"I have a continuing post. Now helping everywhere is officially somewhere.",
		],
	},
	&"intern_tilly": {
		&"onboard": [
			"The dashboard tracks every minute I spend learning. It is nice to know somebody is paying attention!",
			"They gave me admin access because proper training would take all afternoon. I learn best under real consequences.",
			"My headset records calls for quality. I love that quality gets to remember everything.",
		],
		&"guided_shadow": [
			"I watch the automation handle files, then handle everything it flags. It is like being the human part of the feature!",
			"My mentor shared her screen and her task list. The screen stopped sharing, but the task list stayed.",
			"I get to classify exceptions the model cannot understand. That means my judgment is technically indispensable.",
		],
		&"stretch_project": [
			"They asked me to ship the dashboard before requirements settle. That is real agile experience!",
			"If the pilot succeeds, it belongs to Innovation. If it fails, I get a very detailed learning review.",
			"I am on call for the stretch launch. The app cannot sleep, so it is nice that I can keep it company.",
		],
		&"culture_sprint": [
			"I built a morale pulse that asks every hour. More data should make everyone feel more heard!",
			"The dashboard says participation is voluntary and sends reminders until it is complete.",
			"I anonymized the survey by replacing names with employee numbers. Privacy is so clever.",
		],
		&"term_complete": [
			"My access expires tonight, except for the alerts they still need me to monitor.",
			"The system gave me an excellent performance score. The hiring system is apparently a separate system.",
			"I completed the rotation with zero untracked minutes. The dashboard and I are both very proud.",
		],
		&"growth_extension": [
			"They renewed my credentials without changing permissions or pay. Seamless deployment!",
			"I get two more shifts to turn temporary fixes into permanent undocumented infrastructure.",
			"My meal card update generated seven alerts. It feels good to have an economic event in production.",
		],
		&"recommendation_letter": [
			"My recommendation is digitally signed by the system account. Automation really does scale gratitude.",
			"They exported my performance data so I can take the experience with me. The raw file stays here.",
		],
		&"paid_fellowship": [
			"I am officially paid to maintain the tools I built while officially learning. That is a clean migration!",
			"The fellowship added me to Payroll. It only took one term and three emergency releases.",
		],
	},
}


static func speaker(speaker_id: StringName) -> Dictionary:
	return (SPEAKERS.get(speaker_id, {}) as Dictionary).duplicate(true)


static func manager_speaker(candidate_id: StringName) -> StringName:
	return StringName(MANAGER_SPEAKER_BY_CANDIDATE.get(candidate_id, &"cornelius"))


static func intern_speaker(candidate_id: StringName) -> StringName:
	return StringName(INTERN_SPEAKER_BY_CANDIDATE.get(candidate_id, &"intern_lottie"))


static func worker_speaker(worker_id: int) -> StringName:
	if worker_id < 0 or worker_id >= WORKER_SPEAKERS.size():
		return &"mabel"
	return WORKER_SPEAKERS[worker_id]


static func voice_lines(speaker_id: StringName, theme_id: StringName) -> Array:
	var voice := VOICE_POOLS.get(speaker_id, {}) as Dictionary
	return (voice.get(theme_id, []) as Array).duplicate()
