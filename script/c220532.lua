local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon procedure: 1 Psychic Tuner + 1+ non-Tuner monsters
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_PSYCHIC),1,1,Synchro.NonTuner(nil),1,99)
	
	-- 1: If Synchro Summoned: Search 1 "Nocturne Gear" card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	-- 2: Quick Effect (Opponent's Turn): Banish 2 to Synchro Summon from Extra
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,0,EFFECT_COUNT_CODE_CHAIN)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- E1: Nocturne Gear Search
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.thfilter(c)
	return c:IsSetCard(0xd8f) and c:IsAbleToHand() -- Replace 0x777 with Nocturne Gear setcode
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

-- E2: Banish Synchro Logic
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp -- Opponent's turn only
end

-- Filter for Psychic Synchros in Extra Deck
function s.synfilter(c,e,tp,lv)
	return c:IsRace(RACE_PSYCHIC) and c:IsType(TYPE_SYNCHRO) and c:IsLevel(lv)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

-- Filter for materials (Field and GY)
function s.matfilter(c)
	return c:IsRace(RACE_PSYCHIC) and c:IsAbleToRemove() and c:HasLevel()
end

-- The selection logic for the 2 monsters
function s.rescon(sg,e,tp,mg)
	if #sg~=2 then return false end
	if not sg:IsExists(Card.IsType,1,nil,TYPE_TUNER) then return false end
	local lv=sg:GetSum(Card.GetLevel)
	return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,lv)
end
-- COST: Selection and Banishment happen here
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	if chk==0 then 
		return Duel.GetLocationCountFromEx(tp)>0
		and aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0) 
	end
	
	local sg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_REMOVE)
	local lv=sg:GetSum(Card.GetLevel)
	e:SetLabel(lv) -- Pass the Level to the Operation
	Duel.Remove(sg,POS_FACEUP,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local lv=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,lv):GetFirst()
	if sc then
		Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end