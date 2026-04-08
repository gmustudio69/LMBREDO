-- <Limit Breaker> Phoenix Ascension
local s, id = GetID()
local KAZARI_ID = 220450 -- Replace with the actual ID of "<Limit Breaker> Kazari"

function s.initial_effect(c)
	-- Xyz Summon
	Xyz.AddProcedure(c, aux.FilterBoolFunctionEx(Card.IsRace, RACE_WARRIOR), 7, 2)
	c:EnableReviveLimit()

	-- This card becomes "<Limit Breaker> Kazari" while on the field
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_ONFIELD)
	e1:SetValue(KAZARI_ID)
	c:RegisterEffect(e1)

	-- Standby Phase: If this card is a Continuous Spell: You can Special Summon this card
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE + PHASE_STANDBY)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- Ignition Effect: Detach 1, target 1 monster on field or GY; place it as a Continuous Spell
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id) -- HOPT
	e3:SetCost(s.plcost) -- Detach 1 material
	e3:SetTarget(s.pctg)
	e3:SetOperation(s.pcop)
	c:RegisterEffect(e3)

	-- Quick Effect: When a Spell/Trap or effect is activated, negate and destroy
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 2))
	e4:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1, id + 1) -- Second HOPT (tracks separately using id + 1)
	e4:SetCondition(s.negcon)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end
s.listed_names={220450,id}
-- Standby Phase Special Summon Condition
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
function s.plcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
-- Filter for placing monsters into the Spell/Trap zone
-- Note: Checks if the specific OWNER of the card has an empty Spell/Trap zone
function s.pcfilter(c)
	if c:IsForbidden() or not c:IsMonster() then return false end
	local p = c:GetOwner()
	return Duel.GetLocationCount(p, LOCATION_SZONE) > 0
end

-- Place as Spell Target
function s.pctg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE + LOCATION_GRAVE) and s.pcfilter(chkc) end
	if chk == 0 then return Duel.IsExistingTarget(s.pcfilter, tp, LOCATION_MZONE + LOCATION_GRAVE, LOCATION_MZONE + LOCATION_GRAVE, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
	Duel.SelectTarget(tp, s.pcfilter, tp, LOCATION_MZONE + LOCATION_GRAVE, LOCATION_MZONE + LOCATION_GRAVE, 1, 1, nil)
end

-- Place as Spell Operation
function s.pcop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) or tc:IsImmuneToEffect(e) then return end
	local p = tc:GetOwner()
	
	-- Verify owner still has a zone open at resolution
	if Duel.GetLocationCount(p, LOCATION_SZONE) <= 0 then return end
	if Duel.MoveToField(tc, tp, p, LOCATION_SZONE, POS_FACEUP, true) then
		-- Treat as Continuous Spell
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET)
		e1:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
		tc:RegisterEffect(e1)
	end
end
-- Omni-Negate Condition
-- =========================================================
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
	-- Must not be destroyed by battle AND the activated effect must be a Spell or Trap
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) 
		and re:IsActiveType(TYPE_SPELL+TYPE_TRAP) 
		and Duel.IsChainNegatable(ev)
end
function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
	end
end
function s.negop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg, REASON_EFFECT)
	end
end