/obj/effect/proc_holder/spell/targeted/area_teleport
	name = "Area teleport"
	desc = "This spell teleports you to a type of area of your selection."
	mobs_blacklist = list(/mob/living/brain, /mob/living/silicon/pai)

	var/randomise_selection = 0 //if it lets the usr choose the teleport loc or picks it from the list
	var/invocation_area = 1 //if the invocation appends the selected area
	var/sound1 = 'sound/weapons/zapbang.ogg'
	var/sound2 = 'sound/weapons/zapbang.ogg'

/obj/effect/proc_holder/spell/targeted/area_teleport/perform(list/targets, recharge = 1,mob/living/user = usr)
	var/thearea = before_cast(targets)
	if(!thearea || !cast_check(1))
		revert_cast()
		return
	invocation(thearea,user)
	if(charge_type == "recharge" && recharge)
		INVOKE_ASYNC(src, PROC_REF(start_recharge))
	cast(targets,thearea,user)
	after_cast(targets)

/obj/effect/proc_holder/spell/targeted/area_teleport/before_cast(list/targets)
	var/area/U = get_area(usr)
	if(U.noteleport && !istype(U, /area/wizard_station)) // Wizard den special check for those complaining about being unable to tele on station.
		to_chat(usr, "<span class='warning'>Unseen forces prevent you from casting this spell in this area</span>")
		return
	var/A
	if(!randomise_selection)
		A = input("Area to teleport to", "Teleport", A) as null|anything in GLOB.teleportlocs
	else
		A = pick(GLOB.teleportlocs)
	if(!A)
		return
	var/area/thearea = GLOB.teleportlocs[A]

	return thearea

/obj/effect/proc_holder/spell/targeted/area_teleport/cast(list/targets,area/thearea,mob/user = usr)
	playsound(get_turf(user), sound1, 50,1)
	for(var/mob/living/target in targets)
		var/list/L = list()
		for(var/turf/T in get_area_turfs(thearea.type))
			if(!T.density)
				var/clear = 1
				for(var/obj/O in T)
					if(O.density)
						clear = 0
						break
				if(clear)
					L+=T

		if(!L.len)
			to_chat(usr, "The spell matrix was unable to locate a suitable teleport destination for an unknown reason. Sorry.")
			return

		if(target && target.buckled)
			target.buckled.unbuckle_mob(target, force=1)

		var/forcecheck = istype(get_area(target), /area/wizard_station)
		var/list/tempL = L
		var/attempt = null
		var/success = 0
		while(tempL.len)
			attempt = pick(tempL)
			do_teleport(target, attempt, channel = TELEPORT_CHANNEL_MAGIC, forced = forcecheck)
			if(get_turf(target) == attempt)
				success = 1
				break
			else
				tempL.Remove(attempt)

		if(!success)
			do_teleport(target, L, forceMove = TRUE, channel = TELEPORT_CHANNEL_MAGIC, forced = forcecheck)
			playsound(get_turf(user), sound2, 50,1)

	return

/obj/effect/proc_holder/spell/targeted/area_teleport/invocation(area/chosenarea = null,mob/user = usr)
	if(!invocation_area || !chosenarea)
		..()
	else
		switch(invocation_type)
			if("shout")
				user.say("[invocation] [uppertext(chosenarea.name)]", forced = "spell")
				playsound(user.loc, pick('sound/misc/null.ogg'), 100, 1)
			if("whisper")
				user.whisper("[invocation] [uppertext(chosenarea.name)]")

	return
