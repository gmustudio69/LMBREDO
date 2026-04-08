-- Axiarch Ignition - Edicts
local s, id = GetID()
local SET_AXIARCH = 0xe1f -- REPLACE THIS with the actual Setcode you assigned to "Axiarch" in your database!
function s.initial_effect(c)
	-- Effect 1: Special Summon from Hand
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	-- Hard Once Per Turn for this inherent summon method
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- Effect 2: Search/Salvage 1 "Axiarch" Spell/Trap
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1}) -- First effect HOPT
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Effect 3: Destroy & Burn when sent to GY for an Xyz monster's effect
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 2))
	e4:SetCategory(CATEGORY_DESTROY + CATEGORY_DAMAGE)
	e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetCountLimit(1,{id,2}) -- Second effect HOPT
	e4:SetCondition(s.descon)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)
end

-- =========================================================
-- Effect 1: Special Summon Condition
-- =========================================================
function s.spfilter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_EARTH)
end
function s.spcon(e, c)
	if c == nil then return true end
	local tp = c:GetControler()
	return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_MZONE, 0, 1, nil)
end
function s.thfilter(c)
	return c:IsSetCard(SET_AXIARCH) and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsAbleToHand()
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK + LOCATION_GRAVE)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	-- aux.NecroValleyFilter ensures it doesn't bypass Necrovalley if pulling from GY
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.thfilter), tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end

-- =========================================================
-- Effect 3: Destroy & Burn
-- =========================================================
function s.descon(e, tp, eg, ep, ev, re, r, rp)
	return re and re:GetHandler():IsType(TYPE_XYZ) and (r & REASON_COST) ~= 0
end
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1 - tp) end
	-- "Target 1 monster your opponent controls" - Nil filter allows both Face-Up and Face-Down targets
	if chk == 0 then return Duel.IsExistingTarget(nil, tp, 0, LOCATION_MZONE, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp, nil, tp, 0, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
	-- Pre-calculate damage for the preview window
	local tc = g:GetFirst()
	local atk = 0
	if tc:IsFaceup() then atk = tc:GetBaseAttack() end
	if atk < 0 then atk = 0 end
	Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1 - tp, math.floor(atk / 2))
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		-- Gets Original ATK
		local atk = tc:GetBaseAttack() 
		if atk < 0 then atk = 0 end
		-- Destroy it, and if you do, inflict damage
		if Duel.Destroy(tc, REASON_EFFECT) > 0 then
			Duel.Damage(1 - tp, math.floor(atk / 2), REASON_EFFECT)
		end
	end
end