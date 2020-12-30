--==============================================================
--******			       CITY STATES      			  ******
--==============================================================

-- Ngazargamu give 10% reduction insead on 20% reduction
UPDATE ModifierArguments SET Value='10' WHERE 
	ModifierId='MINOR_CIV_NGAZARGAMU_BARRACKS_STABLE_PURCHASE_BONUS' AND
	Name="Amount";
UPDATE ModifierArguments SET Value='10' WHERE 
	ModifierId='MINOR_CIV_NGAZARGAMU_ARMORY_PURCHASE_BONUS' AND
	Name="Amount";
UPDATE ModifierArguments SET Value='10' WHERE 
	ModifierId='MINOR_CIV_NGAZARGAMU_MILITARY_ACADEMY_PURCHASE_BONUS' AND
	Name="Amount";

-- Allow Nihang to be affected by Akkad
INSERT INTO Modifiers 
	(ModifierId, ModifierType, SubjectRequirementSetId)
	VALUES
	('MINOR_CIV_AKKAD_UNIQUE_INFLUENCE_BONUS_NIHANG', "MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER", "PLAYER_IS_SUZERAIN"),
	('MINOR_CIV_AKKAD_ENABLE_WALL_ATTACK_WHOLE_GAME_NIHANG', "MODIFIER_PLAYER_UNITS_ADJUST_ENABLE_WALL_ATTACK_WHOLE_GAME_PROMOTION_CLASS", NULL);

INSERT INTO ModifierArguments
	(ModifierId, Name, Type, Value)
	VALUES
	('MINOR_CIV_AKKAD_ENABLE_WALL_ATTACK_WHOLE_GAME_NIHANG', 'PromotionClass', 'ARGTYPE_IDENTITY', 'PROMOTION_CLASS_NIHANG'),
	('MINOR_CIV_AKKAD_UNIQUE_INFLUENCE_BONUS_NIHANG', 'ModifierId', 'ARGTYPE_IDENTITY','MINOR_CIV_AKKAD_ENABLE_WALL_ATTACK_WHOLE_GAME_NIHANG');

INSERT INTO TraitModifiers
    (TraitType, ModifierId)
    VALUES
    ('MINOR_CIV_AKKAD_TRAIT','MINOR_CIV_AKKAD_UNIQUE_INFLUENCE_BONUS_NIHANG');