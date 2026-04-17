-- <Limit Breaker> Fairy Mirage
local s, id = GetID()
local KAZARI_ID = 220450 -- Replace with the actual ID of "<Limit Breaker> Kazari"

function s.initial_effect(c)
	-- Must be properly summoned
	c:EnableReviveLimit()
	-- Link Summon Procedure: 2 monsters with the same Attribute
	Link.AddProcedure(c, nil, 2, 2, s.lcheck)
	-- Cannot Special Summon this card, unless you control Kazari or a
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_COST)
	e0:SetCost(s.spcost)
	c:RegisterEffect(e0)

	-- This card becomes "<Limit Breaker> Kazari" while on the field
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_CHANGE_CODE)
	e2:SetRange(LOCATION_ONFIELD)
	e2:SetValue(KAZARI_ID)
	c:RegisterEffect(e2)

	-- Standby Phase: If this card is a Continuous Spell: You can Special Summon this card
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE + PHASE_STANDBY)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	-- Quick Effect: Target up to 2 monsters you control/GY; place them as Cont. Spells, then bounce cards
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id) -- HOPT limit
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end
s.listed_names={220450,id}
-- Link Summon check: 2 monsters with the exact same Attribute
function s.lcheck(g, lc, sumtype, tp)
	return g:GetClassCount(Card.GetAttribute) == 1
end

-- Special Summon restriction check
function s.cfilter(c)
	return c:IsFaceup() and (c:IsCode(KAZARI_ID) or c:ListsCode(KAZARI_ID))
end
function s.spcost(e,se,sp,st)
	return Duel.IsExistingMatchingCard(s.cfilter, e:GetHandlerPlayer(), LOCATION_MZONE,0, 1, nil)
end

-- Standby Phase Special Summon Condition (Must be a Continuous Spell)
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and e:GetHandler():IsCanBeSpecialSummoned(e, 0, tp, false, false) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- Filter for placing monsters into the Spell/Trap zone
function s.pcfilter(c)
	return c:IsMonster() and ((c:IsLocation(LOCATION_MZONE) and c:IsFaceup()) or c:IsLocation(LOCATION_GRAVE)) and not c:IsForbidden()
end

-- Quick Effect Target
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE + LOCATION_GRAVE) and chkc:IsControler(tp) and s.pcfilter(chkc) end
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
		and Duel.IsExistingTarget(s.pcfilter, tp, LOCATION_MZONE + LOCATION_GRAVE, 0, 1, nil) end
	local ft = Duel.GetLocationCount(tp, LOCATION_SZONE)
	local max = math.min(2, ft)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
	local g = Duel.SelectTarget(tp, s.pcfilter, tp, LOCATION_MZONE + LOCATION_GRAVE, 0, 1, max, nil)
	Duel.SetPossibleOperationInfo(0, CATEGORY_TOHAND, nil, 1, 1 - tp, LOCATION_ONFIELD)
end

-- Quick Effect Operation
function s.thop(e, tp, eg, ep, ev, re, r, rp)
	local tg = Duel.GetTargetCards(e)
	if #tg == 0 then return end
	local ft = Duel.GetLocationCount(tp, LOCATION_SZONE)
	if ft < #tg then return end -- Cannot resolve if zones are suddenly blocked
	
	local placed = 0
	for tc in aux.Next(tg) do
		if Duel.MoveToField(tc, tp, tc:GetOwner(), LOCATION_SZONE, POS_FACEUP, true) then
			-- Treat as Continuous Spell
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetCode(EFFECT_CHANGE_TYPE)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET)
			e1:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
			tc:RegisterEffect(e1)
			placed = placed + 1
		end
	end
end