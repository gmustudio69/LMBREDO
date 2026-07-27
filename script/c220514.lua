-- Limit Overdrive - Resonance
local s, id = GetID()
function s.initial_effect(e0)
	-- Activate
	local e1 = Effect.CreateEffect(e0:GetHandler())
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVAT)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_END_PHASE)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	e0:GetHandler():RegisterEffect(e1)
end

-- Filter for valid tributes: "<Limit Breaker> Kazari" on the field (Monster Zone or Face-up Spell & Trap Zone)
function s.tribute_filter(c, tp)
	return c:IsFaceup() and (c:IsCode(220450)) -- Replace 100000000 with "<Limit Breaker> Kazari"'s actual passcode
		and (c:IsControler(tp) and (c:IsLocation(LOCATION_MZONE) or (c:IsLocation(LOCATION_SZONE) and c:IsType(TYPE_MONSTER))))
		and Duel.IsExistingMatchingCard(s.negate_filter, tp, 0, LOCATION_ONBOARD, 1, nil) -- at least 1 valid target exists
end

function s.negate_filter(c)
	return c:IsFaceup() and not c:IsDisabled()
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	local rg = Duel.GetReleaseGroup(tp):Filter(function(c)
		return c:IsFaceup() and c:IsCode(220450) -- Replace 100000000 with Kazari's passcode
			and (c:IsLocation(LOCATION_MZONE) or (c:IsLocation(LOCATION_SZONE) and c:IsType(TYPE_MONSTER)))
	end, nil)

	if chk == 0 then
		return #rg > 0 and Duel.IsExistingMatchingCard(Card.IsNegatable, tp, LOCATION_ONBOARD, LOCATION_ONBOARD, 1, nil)
	end

	-- Let the player choose any number of Kazari cards to tribute
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
	local tg = rg:Select(tp, 1, #rg, nil)
	local ct = #tg
	
	-- Save the tribute count into the effect structure to use in the operation
	e:SetLabel(ct)
	
	-- Perform the tribute cost immediately as part of target/cost evaluation or setup
	Duel.Release(tg, REASON_COST)

	-- Target cards on the field equal to the number tributed
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISABLE)
	local g = Duel.SelectTarget(tp, Card.IsNegatable, tp, LOCATION_ONBOARD, LOCATION_ONBOARD, ct, ct, nil)
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, ct, 0, 0)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS)
	if not g then return end
	
	local tc = g:GetFirst()
	while tc do
		if tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsDisabled() then
			-- Negate effects
			Duel.NegateRelatedChain(tc, RESET_TURN_SET)
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
			tc:RegisterEffect(e1)
			local e2 = Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
			tc:RegisterEffect(e2)
		end
		tc = g:GetNext()
	end
end