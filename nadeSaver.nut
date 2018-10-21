this.TOGGLE_BUTTON <- "F5";
this.SLOT_BUTTONS <- ["F6", "F7", "F8"];
this.TYPE_HE <- "hegrenade_projectile";
this.TYPE_FLASH <- "flashbang_projectile";
this.TYPE_SMOKE <- "smokegrenade_projectile";
this.TYPE_MOLOTOV <- "molotov_projectile";
this.TYPE_DECOY <- "decoy_projectile";
this.TYPES <- [TYPE_HE, TYPE_FLASH, TYPE_SMOKE, TYPE_MOLOTOV, TYPE_DECOY];
this.currentSlot <- 0;
this.nadeSaveMode <- true;
this.savedNades <- [];
this.nadeQueue <- [];

printl(@"nadeSaver executed");
printl(@"type to start: script nadeSetup()");

function nadeSetup() {
	if (!Entities.FindByName(null, "nadeTimer"))
	{
		local nadeTimer = Entities.CreateByClassname("logic_timer");
		EntFireByHandle(nadeTimer, "addoutput", "targetname nadeTimer", 0.0, null, null);
	}

	EntFire("nadeTimer", "addoutput", "refiretime 0.05");
	EntFire("nadeTimer", "enable");
	EntFire("nadeTimer", "addoutput", "startdisabled 0");
	EntFire("nadeTimer", "addoutput", "UseRandomTime 0");
	EntFire("nadeTimer", "addoutput", "ontimer nadeTimer,RunScriptCode,nadeThink()");

    SendToConsole(@"bind """ + TOGGLE_BUTTON + @""" ""script toggleNadeSaving()""");

	for (local i = 0; i < SLOT_BUTTONS.len(); ++i) {
    	SendToConsole(@"bind """ + SLOT_BUTTONS[i] + @""" ""script queueNade(" + i + @")""");
		savedNades.push(null);
	}
}

function nadeThink() {
	local nade = null;

	foreach (type in TYPES) {
		while (nade = Entities.FindByClassname(nade, type)) {
			if (nadeQueue.len() > 0) {
				spawnNade(nade, type);
			} else if (nadeSaveMode) {
				saveNade(nade, type);
			}
		}
	}
}

function isNadeUsed(nade) {
	// This is a hack, we mark used nades by giving them a random health
	if (nade.GetHealth() == 1337) {
		return true;
	}
}

function markNadeUsed(nade) {
	nade.SetHealth(1337);
}

function saveNade(nade, type) {
	if (isNadeUsed(nade)) return;

	markNadeUsed(nade);

	local savedNade = {};

	savedNade["type"] <- type;
	savedNade["vel"] <- nade.GetVelocity();
	savedNade["pos"] <- nade.GetCenter();
	savedNade["angles"] <- nade.GetAngles();
	savedNade["angularVelocity"] <- nade.GetAngularVelocity();

	savedNades[currentSlot] = savedNade;

	ScriptPrintMessageCenterAll("Saved grenade to " + SLOT_BUTTONS[currentSlot]);
}

function spawnNade(nade, type) {
	for (local i = 0; i < nadeQueue.len(); ++i) {
		local savedNade = nadeQueue[i];

		if (savedNade.type != type)
			continue;

		if (isNadeUsed(nade)) continue;

		markNadeUsed(nade);

		nade.SetAbsOrigin(savedNade["pos"]);
		nade.SetVelocity(savedNade["vel"]);
		nade.SetAngles(savedNade["angles"].x, savedNade["angles"].y, savedNade["angles"].z);
		nade.SetAngularVelocity(savedNade["angularVelocity"].x, savedNade["angularVelocity"].y, savedNade["angularVelocity"].z);

		if (type == TYPE_HE || savedNade.type == TYPE_MOLOTOV) {
			EntFireByHandle(nade, "InitializeSpawnFromWorld", "", 0.0, nade.GetOwner(), nade.GetOwner());
		}

		nadeQueue.remove(i);
		return;
	}
}

function toggleNadeSaving() {
	foreach (type in TYPES) {
		SendToConsole(@"ent_fire " + type + " kill");
	}

	if (nadeSaveMode) {
		nadeSaveMode = false;
		ScriptPrintMessageCenterAll("Grenade saving disabled");
	} else {
		nadeSaveMode = true;
		currentSlot = (currentSlot + 1) % SLOT_BUTTONS.len();
		ScriptPrintMessageCenterAll("Saving next grenade to " + SLOT_BUTTONS[currentSlot]);
	}
}

function queueNade(slot) {
	local savedNade = savedNades[slot];

	if (savedNade == null) {
		ScriptPrintMessageCenterAll("No grenade has been saved to slot " + SLOT_BUTTONS[slot]);
		return;
	}

    SendToConsole(@"ent_create " + savedNade.type);
	nadeQueue.push(savedNade);
}
