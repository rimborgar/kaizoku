/mob/living/carbon/human/species/goblin
	race = /datum/species/goblin

/datum/species/goblin
	name = "Goblin"
	id = "goblin"
	desc = "Goblin are the creation of Eora and Graggar's affair."
	default_color = "FFFFFF"
	species_traits = list(EYECOLOR,HAIR,FACEHAIR,LIPS,STUBBLE,OLDGREY)
	inherent_traits = list(TRAIT_NOMOBSWAP)
	default_features = list("mcolor" = "FFF", "wings" = "None")
	use_skintones = 1
	possible_ages = list(AGE_YOUNG, AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD)
	skinned_type = /obj/item/stack/sheet/animalhide/human
	disliked_food = NONE
	liked_food = NONE
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | ERT_SPAWN | RACE_SWAP | SLIME_EXTRACT
	limbs_icon_m = 'icons/roguetown/mob/bodies/m/mg.dmi'
	limbs_icon_f = 'icons/roguetown/mob/bodies/m/mg.dmi'
	dam_icon = 'icons/roguetown/mob/bodies/dam/dam_male.dmi'
	dam_icon_f = 'icons/roguetown/mob/bodies/dam/dam_female.dmi'
	hairyness = "t1"
	soundpack_m = /datum/voicepack/male/zeth
	soundpack_f = /datum/voicepack/female/
	offset_features = list(OFFSET_ID = list(0,0), OFFSET_GLOVES = list(0,0), OFFSET_WRISTS = list(0,0),\
	OFFSET_CLOAK = list(0,0), OFFSET_FACEMASK = list(0,5), OFFSET_HEAD = list(0,-4), \
	OFFSET_FACE = list(0,-4), OFFSET_BELT = list(0,-5), OFFSET_BACK = list(0,-4), \
	OFFSET_NECK = list(0,-4), OFFSET_MOUTH = list(0,-4), OFFSET_PANTS = list(0,0), \
	OFFSET_SHIRT = list(0,0), OFFSET_ARMOR = list(0,0), OFFSET_HANDS = list(0,1), OFFSET_UNDIES = list(0,1), \
	OFFSET_ID_F = list(0,-1), OFFSET_GLOVES_F = list(0,0), OFFSET_WRISTS_F = list(0,0), OFFSET_HANDS_F = list(0,0), \
	OFFSET_CLOAK_F = list(0,0), OFFSET_FACEMASK_F = list(0,-1), OFFSET_HEAD_F = list(0,-3), \
	OFFSET_FACE_F = list(0,-5), OFFSET_BELT_F = list(0,-5), OFFSET_BACK_F = list(0,-5), \
	OFFSET_NECK_F = list(0,-5), OFFSET_MOUTH_F = list(0,-5), OFFSET_PANTS_F = list(0,0), \
	OFFSET_SHIRT_F = list(0,0), OFFSET_ARMOR_F = list(0,0), OFFSET_UNDIES_F = list(0,0))
	specstats = list("strength" = 0, "perception" = -1, "intelligence" = -2, "constitution" = 1, "endurance" = 1, "speed" = 1, "fortune" = 1)
	specstats_f = list("strength" = -1, "perception" = 1, "intelligence" = -1, "constitution" = 0, "endurance" = 0, "speed" = 2, "fortune" = 0)
	enflamed_icon = "widefire"
	possible_faiths = list(FAITH_PSYDON)
	mutanteyes = /obj/item/organ/eyes/goblin

/datum/species/goblin/check_roundstart_eligible()
	return TRUE

/datum/species/goblin/get_skin_list()
	return sortList(list(
	"Eoran" = "9FC460",
	"Grumysand" = "6E582B",
	"Wornoutboot" = "645B3B",
	"Palegrimlin" = "4F6252",
	"Sickly" = "7C957D",
	"Soiled" = "527364",
	"Goober" = "6B7554",
	"Rottenolive" = "6F7246",
	"Hobgob" = "926818",
	"Lystic" = "668578",
	"Tarnished" = "3C440B",
	"Graggoric" = "3D4F2F"
	))

/datum/species/goblin/get_hairc_list()
	return sortList(list(

	"brown - mud" = "362e25",
	"brown - oats" = "584a3b",
	"brown - grain" = "58433b",
	"brown - soil" = "48322a",

	"black - oil" = "181a1d",
	"black - cave" = "201616",
	"black - rogue" = "2b201b",
	"black - midnight" = "1d1b2b",

	))

/datum/species/goblin/random_name(gender,unique,lastname)

	var/randname
	if(unique)
		if(gender == MALE)
			for(var/i in 1 to 10)
				randname = pick( world.file2list("strings/rt/names/human/humnorm.txt") )
				if(!findname(randname))
					break
		if(gender == FEMALE)
			for(var/i in 1 to 10)
				randname = pick( world.file2list("strings/rt/names/human/humnorf.txt") )
				if(!findname(randname))
					break
	else
		if(gender == MALE)
			randname = pick( world.file2list("strings/rt/names/human/humnorm.txt") )
		if(gender == FEMALE)
			randname = pick( world.file2list("strings/rt/names/human/humnorf.txt") )
	return randname

/datum/species/goblin/random_surname()
	return " [pick(world.file2list("strings/rt/names/human/humnorlast.txt"))]"
