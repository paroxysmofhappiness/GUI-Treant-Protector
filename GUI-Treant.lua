local TH = {}
TH.Identity = "treant_heal"
TH.Locale = {
	["name"] = {
		["english"] = "Auto Heal",
		["russian"] = "Авто Хил"
	},
	["desc"] = {
		["english"] = "Automatic heal hero, towers.",
		["russian"] = "Автоматически лечит героев, здания."
	},
	["healhero"] = {
		["english"] = "Automatic heal hero.",
		["russian"] = "Автоматически лечить героев."
	},
	["healtower"] = {
		["english"] = "Automatic heal towers.",
		["russian"] = "Автоматически лечить здания."
	},
	["heal_treshhold"] = {
		["english"] = "Heal treshhold",
		["russian"] = "Хилить только когда ХП меньше чем %"
	},
	["heal_hero_key"] = {
		["english"] = "Heal hero key",
		["russian"] = "Кнопка для хила героев"
	},
	["heal_tower_key"] = {
		["english"] = "Heal tower key",
		["russian"] = "Кнопка для хила зданий"
	},
	["select_hero"] = {
		["english"] = "Select hero to heal",
		["russian"] = "Выберите героев для хила"
	},
	["heroselectingame"] = {
		["english"] = "After game start, return here to select which heroes will be healed.",
		["russian"] = "После начала игры вернитесь сюда, чтобы выбрать, какие герои будут излечены."
	}
	,
	["selectby"] = {
		["english"] = "Select lowest hp",
		["russian"] = "Выбирать наименьшее здоровье"
	}
}
TH.HowSelect  = {
	["english"] = {
		["real"] = "by real hp",
		["perc"] = "by percentage",
	},
	["russian"] = {
		["real"] = "по числу",
		["perc"] = "в процентах",
	}
}

TH.Ability = {}
TH.Ability.Heal = nil
TH.Hero = nil
TH.Time	= 0

function TH.OnDraw()
	if GUI == nil then return end
	
	if not GUI.Exist(TH.Identity) then
		local GUI_Object	= {}
		GUI_Object["perfect_name"]		= TH.Locale['name']
		GUI_Object["perfect_desc"]		= TH.Locale['desc']
		GUI_Object["perfect_author"]	= 'paroxysm'
		GUI_Object["perfect_version"]	= 171223
		GUI_Object["hero"]				= "Treant Protector"
		GUI_Object["category"]			= GUI.Category.Heroes
		GUI.Initialize(TH.Identity, GUI_Object)
		
		GUI.AddMenuItem(TH.Identity,	TH.Identity .. "healhero",			TH.Locale['healhero'],			GUI.MenuType.CheckBox,	0)
		GUI.AddMenuItem(TH.Identity,	TH.Identity .. "healtower",			TH.Locale['healtower'],			GUI.MenuType.CheckBox,	0)
		GUI.AddMenuItem(TH.Identity,	TH.Identity .. "heal_treshhold",	TH.Locale["heal_treshhold"],	GUI.MenuType.Slider,	1,				99,	40)
		GUI.AddMenuItem(TH.Identity,	TH.Identity .. "heal_hero_key",		TH.Locale["heal_hero_key"],		GUI.MenuType.Key,		"Q",			TH.HealHero,	1)
		GUI.AddMenuItem(TH.Identity,	TH.Identity .. "heal_tower_key",	TH.Locale["heal_tower_key"],	GUI.MenuType.Key,		"F",			TH.HealTower,	1)
		GUI.AddMenuItem(TH.Identity,	TH.Identity .. "selectby",			TH.Locale["selectby"],			GUI.MenuType.SelectBox,	TH.HowSelect,	{ "real" },		1)
		GUI.AddMenuItem(TH.Identity,	TH.Identity .. "heroselectingame",	TH.Locale["heroselectingame"],	GUI.MenuType.Label)
		
		TH.OnGameStart()
	end
end

function TH.OnGameStart()
	TH.Ability		= {}
	TH.Ability.Heal	= nil
	TH.Hero			= nil
	TH.Time			= 0
	if not GUI.Exist(TH.Identity) then return end
	if Heroes.GetLocal() == nil then return end
	if NPC.GetUnitName(Heroes.GetLocal()) ~= "npc_dota_hero_treant" then return end

	if	GUI.MenuExist(TH.Identity,		TH.Identity .. "heroselectingame") then
		GUI.RemoveMenuItem(TH.Identity, TH.Identity .. "heroselectingame")
	end
	
	if	GUI.MenuExist(TH.Identity,		TH.Identity .. "select_hero") then
		GUI.RemoveMenuItem(TH.Identity, TH.Identity .. "select_hero")
	end
	
	local herotable = {}
	for k, v in pairs(Heroes.GetAll()) do
		if Entity.IsSameTeam(Heroes.GetLocal(), v) then
			local name		= NPC.GetUnitName(v)
			herotable[name]	= name
		end
	end
	
	GUI.AddMenuItem(TH.Identity, TH.Identity .. "select_hero", TH.Locale["select_hero"], 
		GUI.MenuType.ImageBox, Length(herotable), herotable, nil, nil, nil, nil)
		
	GUI.Set(TH.Identity .. "select_hero", herotable)
end

function TH.OnGameEnd()
	if	GUI.MenuExist(TH.Identity,		TH.Identity .. "select_hero") then
		GUI.RemoveMenuItem(TH.Identity, TH.Identity .. "select_hero")
	end
	
	if	not GUI.MenuExist(TH.Identity,		TH.Identity .. "heroselectingame") then
		GUI.AddMenuItem(TH.Identity,		TH.Identity .. "heroselectingame",	TH.Locale["heroselectingame"],	GUI.MenuType.Label)
	end
end

function TH.OnUpdate()
	TH.Hero = Heroes.GetLocal()
	if	TH.Hero == nil
		or	NPC.GetUnitName(TH.Hero)	~=	"npc_dota_hero_treant"
		or	Entity.IsDormant(TH.Hero)
		or	not Entity.IsAlive(TH.Hero)
	then return end
	
	TH.Ability.Heal = NPC.GetAbility(TH.Hero, "treant_living_armor")
	if TH.Ability.Heal == nil or not Ability.IsCastable(TH.Ability.Heal, NPC.GetMana(TH.Hero)) then return end

	for k, v in pairs(NPC.GetModifiers(TH.Hero)) do
		if(Modifier.GetName(v) == "modifier_teleporting") then return end
	end
	
	if	GUI.IsEnabled(TH.Identity) then 	
		TH.Heal(GUI.IsEnabled(TH.Identity .. "healhero"), GUI.IsEnabled(TH.Identity .. "healtower"), tonumber(GUI.Get(TH.Identity .. "heal_treshhold")))
	end
end

function TH.HealHero()
	TH.Heal(true, false, 99)
end

function TH.HealTower()
	TH.Heal(false, true, 99)
end

function TH.Heal(heroes, towers, threshold)
	if	TH.Hero == nil
		or	NPC.GetUnitName(TH.Hero)	~=	"npc_dota_hero_treant"
		or	Entity.IsDormant(TH.Hero)
		or	not Entity.IsAlive(TH.Hero)
	then return end
	if TH.Ability.Heal == nil or not Ability.IsCastable(TH.Ability.Heal, NPC.GetMana(TH.Hero)) then return end
	if GameRules.GetGameTime() < TH.Time then return end
	local min		= 99999
	local uheal		= nil
	local sheroes	= GUI.Get(TH.Identity .. "select_hero", 1)
	local type		= GUI.Get(TH.Identity .. "selectby", 1)[1]
	
	if towers then		
		for k, tower in pairs(NPCs.GetAll()) do
			if Entity.IsSameTeam(TH.Hero, tower) then
				local health = math.abs(Entity.GetHealth(tower))
				local perc = math.floor(health / math.abs(Entity.GetMaxHealth(tower)) * 100)
				local tcheck	= perc < min
				if	type == "real" then
					tcheck		= health < min
				end
				
				if	health > 0
					and NPC.IsTower(tower)
					and tcheck
					and perc <= threshold
					and	Entity.IsAlive(tower)
					and	not Entity.IsDormant(tower)
					and not NPC.HasModifier(tower, "modifier_invulnerable")
				then				
					if	type == "real" then
						min	= health
					else
						min	= perc
					end
					uheal	= tower
				end
			end
		end
	end
	
	min		= 99999
	
	if heroes then
		for k, hero in pairs(Heroes.GetAll()) do
			if Entity.IsSameTeam(TH.Hero, hero) then
				local health	= math.abs(Entity.GetHealth(hero))
				local perc		= math.floor(health / math.abs(Entity.GetMaxHealth(hero)) * 100)
				local tcheck	= perc < min
				if	type == "real" then
					tcheck		= health < min
				end
				
				if	health > 0
					and perc <= threshold
					and tcheck
					and	not NPC.IsIllusion(hero)
					and	Entity.IsAlive(hero)
					and	not Entity.IsDormant(hero)
					and hasValue(sheroes, NPC.GetUnitName(hero))
				then
					if	type == "real" then
						min	= health
					else
						min	= perc
					end
					uheal	= hero
				end
			end
		end
	end
	
	if uheal ~= nil then
		GUI.Write(NPC.GetUnitName(uheal))
		Ability.CastTarget(TH.Ability.Heal, uheal)
		TH.Time = GameRules.GetGameTime() + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) + Ability.GetCastPoint(TH.Ability.Heal) + 0.5
	end
end

return TH