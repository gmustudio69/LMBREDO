--Rikka Fairy Camellia
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon Procedure: 2 Plant monsters, including at least 1 "Rikka"
	Link.AddProcedure(c,s.matfilter,2,2,s.lcheck)
	c:EnableReviveLimit()

	-- ===============================================
	-- Effect 1: Search Rikka Quick-Play Spell (Ignition Effect - "Chậm")
	-- ===============================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ===============================================
	-- Effect 2: Tribute to Salvage (Quick Effect)
	-- ===============================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetCountLimit(1,id+1)
	e2:SetCost(s.salcost)
	e2:SetTarget(s.saltg)
	e2:SetOperation(s.salop)
	c:RegisterEffect(e2)
end

-- Mã định danh của tộc Rikka là 0x141
s.listed_series={0x141}

-- Filter cho Link Material
function s.matfilter(c,lc,sumtype,tp)
	return c:IsRace(RACE_PLANT,lc,sumtype,tp)
end
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0x141,lc,sumtype,tp)
end

-- ===============================================
-- Logic Effect 1 (Search Quick-Play)
-- ===============================================
function s.cfilter(c)
	return c:IsRace(RACE_PLANT) and c:IsAbleToRemoveAsCost()
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.thfilter(c)
	-- Tìm bài Rikka (0x141), là Spell, và là Quick-Play (TYPE_QUICKPLAY)
	return c:IsSetCard(0x141) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_QUICKPLAY) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ===============================================
-- Logic Effect 2 (Tribute & Salvage)
-- ===============================================
function s.tribfilter(c)
	return c:IsRace(RACE_PLANT)
end
function s.salfilter(c)
	return c:IsRace(RACE_PLANT) and c:IsAbleToHand()
end
function s.salcost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Check xem có đủ điều kiện Tribute không (Tribute làm Cost)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,s.tribfilter,1,false,nil) end
	local g=Duel.SelectReleaseGroupCost(tp,s.tribfilter,1,1,false,nil)
	Duel.Release(g,REASON_COST)
end
function s.saltg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.salfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.salfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.salfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.salop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end