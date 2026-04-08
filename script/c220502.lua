-- <Limit Breaker> Ancient Spirit Tree
local s, id = GetID()
local KAZARI_ID = 220450 -- Replace with the actual ID of "<Limit Breaker> Kazari"
local AWAKENING_ID = 100000007 -- Replace with the actual ID of "Limit Break - Awakening"

function s.initial_effect(c)
	-- Must be properly summoned
	c:EnableReviveLimit()
	-- Necessary for EDOPro to recognize mentions of the Ritual Spell and Kazari

	-- This card becomes "<Limit Breaker> Kazari" while on the field
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(KAZARI_ID)
	c:RegisterEffect(e1)

	-- Gains 300 ATK for each "<Limit Breaker> Kazari" on your side of the field
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- If Special Summoned: Apply effects in sequence
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_DISABLE + CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1, id)
	e3:SetTarget(s.efftg)
	e3:SetOperation(s.effop)
	c:RegisterEffect(e3)
end
s.listed_names={220450,id}
-- =========================================================
-- ATK Gain Calculation
-- =========================================================
function s.atkfilter(c)
	return c:IsFaceup() and c:IsCode(KAZARI_ID)
end
function s.atkval(e, c)
	-- Because this card becomes Kazari on the field, it will always count itself!
	return Duel.GetMatchingGroupCount(s.atkfilter, c:GetControler(), LOCATION_ONFIELD, 0, nil) * 300
end

-- =========================================================
-- Sequence Effects
-- =========================================================
function s.thfilter(c)
	return (c:IsCode(KAZARI_ID) or (c:IsMonster() and c:ListsCode(KAZARI_ID))) and c:IsAbleToHand()
end

function s.efftg(e, tp, eg, ep, ev, re, r, rp, chk)
	local ct = Duel.GetMatchingGroupCount(s.atkfilter, tp, LOCATION_ONFIELD, 0, nil)
	-- Check if at least one of the sequence effects can be applied
	local can_negate = ct > 0 and Duel.IsExistingMatchingCard(Card.IsNegatable, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil)
	local can_add = Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_GRAVE, 0, 1, nil)
	
	if chk == 0 then return can_negate or can_add end
	
	if can_negate then
		Duel.SetPossibleOperationInfo(0, CATEGORY_DISABLE, nil, 1, 0, LOCATION_ONFIELD)
	end
	if can_add then
		Duel.SetPossibleOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_GRAVE)
	end
end

function s.effop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	
	-- SEQUENCE 1: Negate face-up cards up to the number of Kazari
	local ct = Duel.GetMatchingGroupCount(s.atkfilter, tp, LOCATION_ONFIELD, 0, nil)
	local ng = Duel.GetMatchingGroup(Card.IsNegatable, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, nil)
	
	if ct > 0 and #ng > 0 then
		if Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then -- Prompt: Do you want to negate cards?
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_NEGATE)
			-- "Up to" allows selecting anywhere from 1 to 'ct'
			local sg = ng:Select(tp, 1, ct, nil)
			for tc in aux.Next(sg) do
				Duel.NegateRelatedChain(tc, RESET_TURN_SET)
				local e1 = Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESET_EVENT + RESETS_STANDARD)
				tc:RegisterEffect(e1)
				local e2 = Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_DISABLE_EFFECT)
				e2:SetValue(RESET_TURN_SET)
				e2:SetReset(RESET_EVENT + RESETS_STANDARD)
				tc:RegisterEffect(e2)
			end
		end
	end

	-- SEQUENCE 2: Add 1 Kazari or mentioned monster from GY
	local thg = Duel.GetMatchingGroup(aux.NecroValleyFilter(s.thfilter), tp, LOCATION_GRAVE, 0, nil)
	if #thg > 0 then
		-- Optional BreakEffect to separate the timing windows slightly, matching "apply in sequence"
		Duel.BreakEffect()
		if Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then -- Prompt: Do you want to add 1 card to your hand?
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
			local sg = thg:Select(tp, 1, 1, nil)
			if #sg > 0 then
				Duel.SendtoHand(sg, nil, REASON_EFFECT)
				Duel.ConfirmCards(1 - tp, sg)
			end
		end
	end
end