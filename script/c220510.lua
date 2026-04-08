-- Light of Unlimited Compassion
local s, id = GetID()
local KAZARI_ID = 220450 -- Replace with the actual ID of "<Limit Breaker> Kazari"

function s.initial_effect(c)
	-- Necessary for EDOPro to recognize "mentions it" effects
	aux.AddCodeList(c, KAZARI_ID)
	-- Activate 1 of these effects
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_names={220450,id}
-- Filter for Kazari OR a monster that mentions Kazari
function s.filter(c)
	return c:IsCode(KAZARI_ID) or (c:IsMonster() and c:ListsCode(KAZARI_ID))
end
-- Filter for searching
function s.thfilter(c)
	return s.filter(c) and c:IsAbleToHand()
end
-- Filter for Special Summoning
function s.spfilter(c, e, tp)
	return s.filter(c) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	-- Check if the player hasn't used Effect 1 this turn and has valid targets
	local b1 = not Duel.HasFlagEffect(tp, id) 
		and Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil)
	-- Check if the player hasn't used Effect 2 this turn and has valid targets
	local b2 = not Duel.HasFlagEffect(tp, id + 1) and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 
		and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_GRAVE, 0, 1, nil, e, tp)
	if chk == 0 then return b1 or b2 end
	
	local op = 0
	-- If both effects are available, prompt the player to choose
	if b1 and b2 then
		op = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1))
	elseif b1 then
		op = Duel.SelectOption(tp, aux.Stringid(id, 0))
	else
		op = Duel.SelectOption(tp, aux.Stringid(id, 1)) + 1
	end
	e:SetLabel(op)
	
	-- Register the Once-Per-Turn flag and set the Chain Category based on the choice
	if op == 0 then
		Duel.RegisterFlagEffect(tp, id, RESET_PHASE + PHASE_END, 0, 1)
		e:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
		Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
	else
		Duel.RegisterFlagEffect(tp, id + 1, RESET_PHASE + PHASE_END, 0, 1)
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_GRAVE)
	end
end
function s.activate(e, tp, eg, ep, ev, re, r, rp)
	local op = e:GetLabel()
	if op == 0 then
		-- Execute Effect 1: Search
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
		local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
		if #g > 0 then
			Duel.SendtoHand(g, nil, REASON_EFFECT)
			Duel.ConfirmCards(1 - tp, g)
		end
	else
		-- Execute Effect 2: Special Summon
		if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
		local tc = g:GetFirst()
		
		if tc and Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP) > 0 then
			-- Apply restriction: Cannot attack directly this turn
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetDescription(3200) -- Built-in EDOPro string for "Cannot attack directly"
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_CLIENT_HINT)
			e1:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
			tc:RegisterEffect(e1)
		end
	end
end