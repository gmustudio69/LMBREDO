--Pyrea V.S Eldrion
local s,id=GetID()

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Monster effects cannot be chained
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	local ge=Effect.GlobalEffect()
	ge:SetType(EFFECT_TYPE_FIELD)
	ge:SetCode(EFFECT_CANNOT_INACTIVATE)
	ge:SetValue(s.effectfilter)
	ge:SetReset(RESET_CHAIN)
	Duel.RegisterEffect(ge,tp)

	local ge2=Effect.GlobalEffect()
	ge2:SetType(EFFECT_TYPE_FIELD)
	ge2:SetCode(EFFECT_CANNOT_DISEFFECT)
	ge2:SetValue(s.effectfilter)
	ge2:SetReset(RESET_CHAIN)
	Duel.RegisterEffect(ge2,tp)

	return true
end

function s.effectfilter(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	return te and te:GetHandler():IsMonster()
end

function s.xyzfilter(c,e,tp)
	return c:IsRank(13)
		and c:IsType(TYPE_XYZ)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.rescon(sg,e,tp,mg)
	return sg:GetClassCount(Card.GetCode)==2
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,2,nil,e,tp)
	end

	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,0,PLAYER_ALL,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local dg=Duel.GetMatchingGroup(Card.IsDestructable,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.Destroy(dg,REASON_EFFECT)

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return end

	local g=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,e,tp)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local sg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_SPSUMMON)
	if not sg then return end

	local c1,c2=sg:GetFirst(),sg:GetNext()

	local you,opp

	if c1:GetAttack()<=c2:GetAttack() then
		you=c1
		opp=c2
	else
		you=c2
		opp=c1
	end

	Duel.SpecialSummonStep(you,0,tp,tp,true,false,POS_FACEUP)
	Duel.SpecialSummonStep(opp,0,tp,1-tp,true,false,POS_FACEUP)
	Duel.SpecialSummonComplete()

	local rg=Group.FromCards(you,opp)

	for tc in aux.Next(rg) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetCountLimit(1)
		e1:SetOperation(s.retop)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		tc:RegisterEffect(e1)
	end
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsLocation(LOCATION_MZONE) then
		Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end