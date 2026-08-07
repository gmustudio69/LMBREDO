--<Limit Breaker> Frostmoon
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon procedure: 1 WATER Warrior monster
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.mfilter,1,1)

	-- ==========================================
	-- MONSTER EFFECTS
	-- ==========================================
	-- 1. On Link Summon: Pay 800 LP, send 1 "Limit Breaker" from ED to GY, place Glaciel in face-up ED
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOEXTRA)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.lkcon)
	e1:SetCost(s.lkcost)
	e1:SetTarget(s.lktg)
	e1:SetOperation(s.lkop)
	c:RegisterEffect(e1)

	-- 2. Quick Effect: Shuffle this card into ED -> Special Summon "<Limit Breaker> Ann"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- Definitions & Setcodes
-- ==========================================
local SET_LIMIT_BREAKER = 0xf86	  -- Replace with your actual "Limit Breaker" setcode
local CARD_ANN		   = 220414   -- Replace with exact ID of "<Limit Breaker> Ann"
local CARD_GLACIEL	   = 886601   -- Replace with exact ID of "<Limit Breaker> Glaciel"

function s.mfilter(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_WATER,lc,sumtype,tp) and c:IsRace(RACE_WARRIOR,lc,sumtype,tp)
end

-- ==========================================
-- E1: On Link Summon Logic
-- ==========================================
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.lkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,800) end
	Duel.PayLPCost(tp,800)
end

function s.tgfilter(c)
	return c:IsSetCard(SET_LIMIT_BREAKER) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end

function s.glacielfilter(c)
	return c:IsCode(CARD_GLACIEL)
end

function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_EXTRA,0,1,nil)
			and Duel.IsExistingMatchingCard(s.glacielfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,nil,1,tp,LOCATION_DECK)
end

function s.lkop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g1>0 and Duel.SendtoGrave(g1,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g2=Duel.SelectMatchingCard(tp,s.glacielfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g2>0 then
			Duel.SendtoExtraP(g2,tp,REASON_EFFECT)
		end
	end
end

-- ==========================================
-- E2: Quick Effect Tag-Out Logic
-- ==========================================
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtraAsCost() end
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

function s.annfilter(c,e,tp)
	return c:IsCode(CARD_ANN) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and (c:IsLocation(LOCATION_HAND) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup()))
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		-- Note: Monster Zone count check accounts for e:GetHandler() moving to Extra Deck during cost
		return Duel.GetMZoneCount(tp,e:GetHandler())>0
			and Duel.IsExistingMatchingCard(s.annfilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.annfilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end