--<World Decoder> Eternal Reality
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()

	--Name becomes <World Decoder> Ellie
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(220405) -- Replace with actual card ID
	c:RegisterEffect(e1)

	--Untargetable while you control a Limit Breaker monster
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.tgcon)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

	--Negate effect from hand/GY/banished
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_NEGATE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id*2)
	e4:SetTarget(s.sptdtg)
	e4:SetOperation(s.sptdop)
	c:RegisterEffect(e4)
end

--Check if you control a Limit Breaker monster
function s.tgfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xf86) -- Assuming "Limit Breaker" set code is 0xCBF
end
function s.tgcon(e)
	return Duel.IsExistingMatchingCard(s.tgfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

--Negation effect condition
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return ep~=tp and (loc==LOCATION_HAND or loc==LOCATION_GRAVE or bit.band(loc,LOCATION_REMOVED)~=0) and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsChainNegatable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateActivation(ev)
end
--Return to Extra Deck and Special Summon
function s.plfilter(c)
	local p=c:GetOwner()
	return c:IsSetCard(0xb67) and c:IsMonster() and c:CheckUniqueOnField(p,LOCATION_SZONE) and not c:IsForbidden()
end
function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectTarget(tp,s.plfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
end
function s.plop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		Duel.MoveToField(tc,tp,tc:GetOwner(),LOCATION_SZONE,POS_FACEUP,true)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
		e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
		tc:RegisterEffect(e1)
	end
end
function s.rescon(sg,e,tp,mg)
	return sg:IsExists(Card.IsRace,1,nil,RACE_WARRIOR) and sg:IsExists(Card.IsRace,1,nil,RACE_PSYCHIC)
		and sg:IsExists(s.spchk,1,nil,e,tp,sg)
end
function s.spchk(c,e,tp,sg)
	return c:IsCanBeSpecialSummoned(e,0,tp,false,false) and (#sg==1 or sg:IsExists(Card.IsAbleToDeck,1,c))
end
function s.sptdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local g=Duel.GetMatchingGroup(s.sptdfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and #g>=2 and aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0) end
	local tg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_TARGET)
	Duel.SetTargetCard(tg)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,tg,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,tg,1,tp,0)
end
function s.sptdop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	if (#tg==0 or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=tg:FilterSelect(tp,s.spchk,1,1,nil,e,tp,tg)
	if #sg>0 and Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)>0 and #tg==2 then
		local dg=tg-sg
		Duel.HintSelection(dg)
		Duel.SendtoDeck(dg,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
	end
end