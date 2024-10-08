
/obj/machinery/crop
	name = "tilled dirt"
	desc = ""
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "blank"
	density = FALSE
	climbable = FALSE
	max_integrity = 0
	var/growth = 0
	var/weeds = 0				//they appear at a value of 50 but don't start damaging the crop until 100
	var/water = 30
	var/food = 30
	var/plant_hp = 30
	var/mphp = 100				//normally plants can't heal if they're dying, but certain things can heal crops to this max
	var/obj/item/seeds/myseed
	var/lastcycle = 0
	var/seesky = TRUE

/obj/machinery/crop/Crossed(atom/movable/AM)
	if(isliving(AM))
		if(myseed)
			plant_hp = max(plant_hp-11, 0)
		else
			qdel(src)
	..()

/obj/machinery/crop/examine(mob/user)
	. = ..()
	if(growth >= 100)
		. += "<span class='notice'>[src] is ready for harvest!</span>"
	if(water < 25)
		. += "<span class='info'>The ground is thirsty.</span>"
	if(food < 25)
		. += "<span class='info'>The ground is hungry.</span>"
	if(weeds > 25)
		. += "<span class='warning'>Weeds!</span>"
	if(plant_hp < 25)
		. += "<span class='warning'>Brown and dying...</span>"

/obj/machinery/crop/process()
	if(QDELETED(src))
		return
	var/needs_update = 0

	if(!myseed)
		STOP_PROCESSING(SSmachines, src)
		qdel(src)
		return

	if(world.time > (lastcycle + 10 SECONDS))
		lastcycle = world.time

//		var/turf/T = loc
//		if(T)
//			for(var/D in GLOB.cardinals)
//				var/turf/TU = get_step(T, D)
//				if(istype(TU, /turf/open/water))
//					water = 100
//					break

		if(seesky)
			plant_hp = max(plant_hp-1, 0) //offset by healing from food if there are not weeds
		else
			plant_hp = max(plant_hp-2, 0)
			weeds = 0
			growth = 0

		if(water > 0)
			if(myseed)
				water = water - myseed.watersucc
			if(weeds >= 50)
				water = water - 1
			water = max(water, 0)
		if(food > 0)
			if(myseed)
				food = food - myseed.foodsucc
			if(weeds >= 50)
				food = food - 1
			else
				if(plant_hp < 100)
					plant_hp = min(plant_hp+1, mphp)
					food = food - 1
			food = max(food, 0)
		if(weeds < 100)
			if(myseed)
				if(growth < 100)
					var/oldgrowth = growth
					growth = growth + (2.5*myseed.growthrate)
					if(oldgrowth < 50 && growth >= 50)
						needs_update = 1
					if(oldgrowth < 100 && growth >= 100)
						needs_update = 1
				if(prob(myseed.weed_chance))
					var/oldweeds = weeds
					weeds = weeds + myseed.weed_rate
					if(weeds >= 50 && oldweeds < 50)
						needs_update = 1
		else if(plant_hp > 0)
			plant_hp = max(plant_hp-5, 0)

		if(myseed)
			if(myseed.yield <= 0) //end of lifespan for long-lived crops
				plant_hp -= 33

		if(plant_hp <= 0)
			STOP_PROCESSING(SSmachines, src)
			var/oldname = name
			name = "dead [oldname]"
			needs_update = 1

	if (needs_update)
		update_seed_icon()

/obj/machinery/crop/Destroy(force=FALSE)
	if(myseed)
		QDEL_NULL(myseed)
	if(istype(loc, /turf/open/floor/rogue/dirt))
		var/turf/open/floor/rogue/dirt/T = loc
		if(T.planted_crop == src)
			T.planted_crop = null
	. = ..()

/obj/machinery/crop/proc/update_seed_icon()
	cut_overlays()
	var/list/layz = list()

	if(myseed) //put the crop on top
		var/gn = 0
		if(plant_hp <= 0) //dead
			if(myseed.obscura)
				opacity = FALSE
				density = FALSE
			gn = 3
		else if(growth >= 50)
			if(myseed.obscura)
				opacity = TRUE
				density = TRUE
			gn = 1
			if(growth >= 100)
				gn = 2
		var/image/crop_overlay = image('icons/roguetown/misc/crops.dmi', "[myseed.species][gn]", "layer"=2.91)
		layz += crop_overlay

	if(weeds >= 50) //put the weeds under
		var/image/weed_overlay = image('icons/roguetown/misc/foliage.dmi', "weeds", "layer"=2.92)
		layz += weed_overlay

	add_overlay(layz)

/obj/machinery/crop/proc/crossed_turf()
	plant_hp -= 1

/obj/machinery/crop/proc/rainedon()
	water = 100

/obj/machinery/crop/attackby(obj/item/attacking_item, mob/user, params)//Full port of Blackstone farming interactions, so you can gain farming skill from doing it.
	if(!isliving(user) || !user.mind)
		return
	var/mob/living/current_farmer = user
	var/datum/mind/farmer_mind = current_farmer.mind
	var/exp_gained = 0

	if(istype(attacking_item, /obj/item/seeds))
		to_chat(user, "<span class='warning'>Something is already growing here.</span>")
		return

	if(istype(attacking_item, /obj/item/rogueweapon/sickle))
		if(!myseed)
			return
		if(plant_hp <= 0)
			to_chat(user, "<span class='warning'>This crop has perished.</span>")
			return
		if(growth < 100)
			to_chat(user, "<span class='warning'>This crop is not ready to harvest.</span>")
			return
		user.visible_message("<span class='notice'>[user] harvests [src] with [attacking_item].</span>")
		for(var/i in 1 to myseed.yield)
			if(plant_hp <= 0)
				return
			var/ttime = 1
			if(!attacking_item.remove_bintegrity(1))
				ttime = 20
			if(!do_after(user, ttime, target = src)) //ROGTODO make this based on farming skill
				break
			new myseed.product(src.loc)
			myseed.yield -= 1
			playsound(src,"plantcross", 100, FALSE)
			exp_gained = round(current_farmer.STAINT / initial(myseed.yield)) //So we don't gain a fuck ton of EXP if our plant happens to have multiple crops
			farmer_mind.adjust_experience(/datum/skill/labor/farming, exp_gained)
		if(myseed.yield <= 0)
			if(myseed.delonharvest)
				qdel(src)
				return
			else
				myseed.timesharvested++
				growth = 0
				myseed.yield = max(initial(myseed.yield) - myseed.timesharvested,0)
			if(!myseed.yield)
				plant_hp = 0
			update_seed_icon()
		return

	if(istype(attacking_item, /obj/item/rogueweapon/hoe))
		if(user.used_intent.type != /datum/intent/till)
			return
		if(plant_hp <= 0)
			playsound(src,'sound/items/seed.ogg', 100, FALSE)
			new /obj/item/natural/fibers(src.loc)
			user.visible_message("<span class='notice'>[user] rips out [src] with [attacking_item].</span>")
			exp_gained = current_farmer.STAINT
			farmer_mind.adjust_experience(/datum/skill/labor/farming, exp_gained)
			qdel(src)
			return
		else if(weeds > 0)
			playsound(src,'sound/items/seed.ogg', 100, FALSE)
			user.visible_message("<span class='notice'>[user] rips out some weeds with [attacking_item].</span>")
			weeds = max(weeds - rand(1,50), 0)
			update_seed_icon()
			exp_gained = current_farmer.STAINT
			farmer_mind.adjust_experience(/datum/skill/labor/farming, exp_gained)
		return

	//Following 3 are fertilizers
	if(istype(attacking_item, /obj/item/natural/poo))
		playsound(src,'sound/items/seed.ogg', 100, FALSE)
		visible_message("<span class='notice'>[user] confidently fertilizes the soil with [attacking_item].</span>")
		qdel(attacking_item)
		user.update_inv_hands()
		food = 100
		exp_gained = current_farmer.STAINT
		farmer_mind.adjust_experience(/datum/skill/labor/farming, exp_gained)
		return
	if(istype(attacking_item, /obj/item/ash) || istype(attacking_item, /obj/item/trash/applecore))
		playsound(src,'sound/items/seed.ogg', 100, FALSE)
		visible_message("<span class='notice'>[user] confidently fertilizes the soil with [attacking_item].</span>")
		food = min(food + 50, 100)
		qdel(attacking_item)
		user.update_inv_hands()
		exp_gained = current_farmer.STAINT
		farmer_mind.adjust_experience(/datum/skill/labor/farming, exp_gained)
		return
	if(istype(attacking_item, /obj/item/reagent_containers/food/snacks))
		var/obj/item/reagent_containers/food/snacks/S = attacking_item
		if(!S.fertamount)
			return
		playsound(src,'sound/items/seed.ogg', 100, FALSE)
		visible_message("<span class='notice'>[user] confidently fertilizes the soil with [attacking_item].</span>")
		food = min(food + S.fertamount, 100)
		qdel(attacking_item)
		user.update_inv_hands()
		exp_gained = current_farmer.STAINT
		farmer_mind.adjust_experience(/datum/skill/labor/farming, exp_gained)
		return
	..()

	if(istype(attacking_item, /obj/item/rogueweapon/hoe))
		if(user.used_intent.type == /datum/intent/till)
			if(plant_hp <= 0)
				playsound(src,'sound/items/seed.ogg', 100, FALSE)
				new /obj/item/natural/fibers(src.loc)
				user.visible_message("<span class='notice'>[user] rips out [src] with [attacking_item].</span>")
				qdel(src)
				return
			else if(weeds > 0)
				playsound(src,'sound/items/seed.ogg', 100, FALSE)
				user.visible_message("<span class='notice'>[user] rips out some weeds with [attacking_item].</span>")
				weeds = max(weeds - rand(1,50), 0)
				update_seed_icon()
		return


	if(istype(attacking_item, /obj/item/natural/poo))
		playsound(src,'sound/items/seed.ogg', 100, FALSE)
		visible_message("<span class='notice'>[user] confidently fertilizes the soil with [attacking_item].</span>")
		qdel(attacking_item)
		user.update_inv_hands()
		food = 100
		return
	if(istype(attacking_item, /obj/item/ash) || istype(attacking_item, /obj/item/trash/applecore))
		playsound(src,'sound/items/seed.ogg', 100, FALSE)
		visible_message("<span class='notice'>[user] confidently fertilizes the soil with [attacking_item].</span>")
		food = min(food + 50, 100)
		qdel(attacking_item)
		user.update_inv_hands()
		return
	if(istype(attacking_item, /obj/item/reagent_containers/food/snacks))
		var/obj/item/reagent_containers/food/snacks/S = attacking_item
		if(S.fertamount)
			playsound(src,'sound/items/seed.ogg', 100, FALSE)
			visible_message("<span class='notice'>[user] confidently fertilizes the soil with [attacking_item].</span>")
			food = min(food + S.fertamount, 100)
			qdel(attacking_item)
			user.update_inv_hands()
			return
	..()


/obj/machinery/crop/attack_hand(mob/living/user, params)
	if(!isliving(user) || !user.mind)
		return
	var/mob/living/current_farmer = user
	var/datum/mind/farmer_mind = current_farmer.mind
	var/exp_gained = 0
	if(!myseed)
		qdel(src)
		return
	var/harvtime = max((60 - (farmer_mind.get_skill_level(/datum/skill/labor/farming) * 10)), 1) //Minimum of 1
	if(plant_hp <= 0)
		if(!do_after(user,harvtime, target = src))
			return
		exp_gained = current_farmer.STAINT
		farmer_mind.adjust_experience(/datum/skill/labor/farming, exp_gained)
		playsound(src,"plantcross", 100, FALSE)
		user.visible_message("<span class='notice'>[user] pulls out [src].</span>")
		new /obj/item/natural/fibers(src.loc)
		qdel(src)
		name = initial(name)
		update_seed_icon()
		return
	if(growth >= 100)
		var/obj/item/offhand = user.get_inactive_held_item()//ghetto farming code starts here
		var/success_chance = 10
		if(offhand)
			var/foundcut = FALSE
			for(var/X in offhand.possible_item_intents)
				var/datum/intent/D = new X
				if(D.blade_class == BCLASS_CUT)
					foundcut = TRUE
					break
			if(foundcut)
				success_chance += 40
				harvtime /= 2 //ghetto farming code ends here
		for(var/i in 1 to myseed.yield)
			if(plant_hp <= 0)
				return
			if(!do_after(user,harvtime, target = src))
				break
			myseed.yield -= 1
			playsound(src,"plantcross", 100, FALSE)
			if(farmer_mind.get_skill_level(/datum/skill/labor/farming))
				success_chance = 100
			if(prob(success_chance))
				new myseed.product(src.loc)
				user.visible_message("<span class='info'>[user] harvests something from [src].</span>")
			else
				user.visible_message("<span class='warning'>[user] spoils something from [src]!</span>")
			exp_gained = round(current_farmer.STAINT / initial(myseed.yield)) //So we don't gain a fuck ton of EXP if our plant happens to have multiple crops
			farmer_mind.adjust_experience(/datum/skill/labor/farming, exp_gained)
		if(myseed.yield <= 0)
			if(myseed.delonharvest)
				qdel(src)
				return
			else
				myseed.timesharvested++
				growth = 0
				myseed.yield = max(initial(myseed.yield) - myseed.timesharvested,0)
			if(!myseed.yield)
				plant_hp = 0
			update_seed_icon()

/obj/machinery/crop/attack_right(mob/living/user, params)
	if(!isliving(user) || !user.mind)
		return
	var/mob/living/current_farmer = user
	var/datum/mind/farmer_mind = current_farmer.mind
	var/exp_gained = 0
	var/deweed_time = max((50 - farmer_mind.get_skill_level(/datum/skill/labor/farming) * 5), 1)
	var/obj/item/offhand = user.get_inactive_held_item()//ghetto farming code starts here
	if(offhand)
		var/foundscoop = FALSE
		for(var/X in offhand.possible_item_intents)
			if(X == /datum/intent/shovelscoop)
				foundscoop = TRUE
				break
		if(foundscoop)
			deweed_time /= 2 //ghetto farming code ends here

	if(weeds <= 0 || !do_after(user, deweed_time, target = src))
		return
	playsound(src,"plantcross", 100, FALSE)
	user.visible_message("<span class='notice'>[user] rips out some weeds.</span>")
	weeds = max(weeds - rand(1,30), 0)
	exp_gained = current_farmer.STAINT
	farmer_mind.adjust_experience(/datum/skill/labor/farming, exp_gained)
	update_seed_icon()
//End of port
