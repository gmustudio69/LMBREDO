-- <Limit Breaker> Ryan
local s, id = GetID()
local KAZARI_ID = 220450 -- Replace with the actual ID of "<Limit Breaker> Kazari"

function s.initial_effect(c)
	-- Effect 1: Special Summon from Hand & Search
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sstg)
	e1:SetOperation(s.ssop)
	c:RegisterEffect(e1)
	-- Effect 2: Burn damage on Normal/Special Summon
	-- Note: Lack of "You can" makes this a Mandatory (Forced) Trigger Effect
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.damtg)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	-- Effect 3: Xyz Summon from Extra Deck while Continuous Spell
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1,{id,2})
	e4:SetCondition(s.xyzcon)
	e4:SetTarget(s.xyztg)
	e4:SetOperation(s.xyzop)
	c:RegisterEffect(e4)
end
s.listed_names={220450,id}
-- =========================================================
-- Effect 1: Special Summon & Search
-- =========================================================
function s.thfilter(c)
	return c:IsCode(KAZARI_ID) and c:IsAbleToHand()
end
function s.sstg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	local opp_has_mon = Duel.GetFieldGroupCount(tp, 0, LOCATION_MZONE) > 0
	
	-- Determine if we can summon to opponent's side or our own side
	local b1 = Duel.GetLocationCount(1-tp, LOCATION_MZONE) > 0 and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP, 1-tp)
	local b2 = opp_has_mon and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP, tp)
	
	if chk == 0 then return (b1 or b2) and Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, LOCATION_HAND)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end
function s.ssop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	local opp_has_mon = Duel.GetFieldGroupCount(tp, 0, LOCATION_MZONE) > 0
	local b1 = Duel.GetLocationCount(1-tp, LOCATION_MZONE) > 0 and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP, 1-tp)
	local b2 = opp_has_mon and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP, tp)
	
	if not (b1 or b2) then return end
	
	-- Assume we summon to opponent's field by default, unless they have a monster and we choose our field
	local sum_tp = 1-tp
	if b1 and b2 then
		if Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then -- Prompt: "Do you want to Special Summon to your field instead?"
			sum_tp = tp
		end
	elseif b2 then
		sum_tp = tp
	end
	
	if Duel.SpecialSummon(c, 0, tp, sum_tp, false, false, POS_FACEUP) > 0 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
		local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
		if #g > 0 then
			Duel.SendtoHand(g, nil, REASON_EFFECT)
			Duel.ConfirmCards(1-tp, g)
		end
	end
end

-- =========================================================
-- Effect 2: Burn Damage
-- =========================================================
function s.damtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(800)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp, 800)
end
function s.damop(e, tp, eg, ep, ev, re, r, rp)
	local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
	Duel.Damage(p, d, REASON_EFFECT)
end

-- =========================================================
-- Effect 3: Xyz Summon as Continuous Spell
-- =========================================================
function s.xyzcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS)
end
function s.xyz_ex_filter(c, e, tp, tc)
	return c:IsRace(RACE_WARRIOR) and c:IsType(TYPE_XYZ) 
		and c:IsAttribute(tc:GetAttribute()) and c:GetRank() == tc:GetLevel() 
		and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_XYZ, tp, false, false) 
		-- We pass 'tc' here to ensure the game knows that zone will free up if it's in the EMZ
		and Duel.GetLocationCountFromEx(tp, tp, tc, c) > 0
end
function s.xyz_target_filter(c, e, tp)
	return c:IsFaceup() and c:IsRace(RACE_WARRIOR) and c:HasLevel()
		and Duel.IsExistingMatchingCard(s.xyz_ex_filter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp, c)
end
function s.xyztg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.xyz_target_filter(chkc, e, tp) end
	if chk == 0 then return Duel.IsExistingTarget(s.xyz_target_filter, tp, LOCATION_MZONE, 0, 1, nil, e, tp) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	Duel.SelectTarget(tp, s.xyz_target_filter, tp, LOCATION_MZONE, 0, 1, 1, nil, e, tp)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end
function s.xyzop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = Duel.GetFirstTarget()
	-- Ensure the target is still viable and the continuous spell is still on the field
	if tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsImmuneToEffect(e) then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local sg = Duel.SelectMatchingCard(tp, s.xyz_ex_filter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp, tc)
		local sc = sg:GetFirst()
		if sc then
			-- Attach the targeted monster to the Xyz monster first
			local mg = Group.FromCards(tc)
			sc:SetMaterial(mg)
			Duel.Overlay(sc, mg)
			
			-- Special Summon the Xyz Monster
			if Duel.SpecialSummon(sc, SUMMON_TYPE_XYZ, tp, tp, false, false, POS_FACEUP) > 0 then
				sc:CompleteProcedure()
				
				-- Attach this card (Ryan) to the summoned monster
				if c:IsRelateToEffect(e) then
					c:CancelToGrave()
					Duel.Overlay(sc, c)
				end
			end
		end
	end
end