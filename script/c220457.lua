--<Limit Breaker> Shadow Catastrophe
local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Special Summon 1 Level 7 LIGHT Warrior and Equip
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- Effect 2: Special Summon Token when sent to GY
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.tktg)
	e3:SetOperation(s.tkop)
	c:RegisterEffect(e3)

end

-- Functions for Effect 1
function s.spfilter(c, e, tp)
	-- Checks for Lv 7 LIGHT Warrior. If banished, must be face-up to verify stats.
	return c:IsLevel(7) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_WARRIOR)
		and (c:IsLocation(LOCATION_DECK) or c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK + LOCATION_GRAVE + LOCATION_REMOVED, 0, 1, nil, e, tp) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK + LOCATION_GRAVE + LOCATION_REMOVED)
	Duel.SetOperationInfo(0, CATEGORY_EQUIP, e:GetHandler(), 1, 0, 0)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	
	-- NecroValleyFilter ensures it can't SS from GY if Necrovalley is active
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter), tp, LOCATION_DECK + LOCATION_GRAVE + LOCATION_REMOVED, 0, 1, 1, nil, e, tp)
	local tc = g:GetFirst()
	
	if tc and Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		-- Equip this card to the summoned monster
		if c:IsRelateToEffect(e) and c:IsFaceup() and c:IsControler(tp) then
			Duel.Equip(tp, c, tc)
			-- Add Equip Limit so the game rules don't immediately destroy the newly equipped spell
			local e1 = Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD)
			e1:SetValue(s.eqlimit)
			e1:SetLabelObject(tc)
			c:RegisterEffect(e1)
		end
	end
end
function s.eqlimit(e, c)
	return c == e:GetLabelObject()
end

function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	and Duel.IsPlayerCanSpecialSummonMonster(tp,220422,0,TYPES_TOKEN,2000,2000,6,RACE_ILLUSION,ATTRIBUTE_DARK)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
	end

 function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,220422,0,TYPES_TOKEN,2000,2000,6,RACE_ILLUSION,ATTRIBUTE_DARK) then return end

	local token=Duel.CreateToken(tp,220422)

	--make it tuner
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ADD_TYPE)
	e1:SetValue(TYPE_TUNER)
	token:RegisterEffect(e1)

	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
end