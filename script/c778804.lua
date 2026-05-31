local s,id=GetID()

function s.initial_effect(c)

	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--------------------------------------------------------
	-- ATK
	--------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	--------------------------------------------------------
	-- DEF
	--------------------------------------------------------
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)

	--------------------------------------------------------
	-- Reveal 3, opponent chooses 1
	--------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

	--------------------------------------------------------
	-- Flip summoned monsters face-down
	--------------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_POSITION+CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetRange(LOCATION_FZONE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.poscon)
	e4:SetTarget(s.postg)
	e4:SetOperation(s.posop)
	c:RegisterEffect(e4)

	local e5=e4:Clone()
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e5)
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(Card.IsAbleToRemove,
		0,LOCATION_REMOVED,LOCATION_REMOVED,nil)*200
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x76b)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.rescon(sg,e,tp,mg)
	return sg:GetClassCount(Card.GetCode)==#sg
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and aux.SelectUnselectGroup(
				Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK,0,nil,e,tp),
				e,tp,3,3,s.rescon,0)
	end

	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,2,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK,0,nil,e,tp)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)

	local sg=aux.SelectUnselectGroup(
		g,e,tp,3,3,s.rescon,1,tp,HINTMSG_CONFIRM)

	if not sg or #sg~=3 then return end

	Duel.ConfirmCards(1-tp,sg)

	local rg=sg:RandomSelect(1-tp,1)
	local tc=rg:GetFirst()

	sg:Sub(rg)

	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	end

	Duel.ShuffleDeck(tp)
end
function s.posfilter(c,tp,e)
	return c:IsSummonPlayer(1-tp)
		and c:IsCanTurnSet()
end

function s.poscon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.posfilter,1,nil,tp)
end
function s.costfilter(c)
	return c:IsSetCard(0x76b)
		and c:IsAbleToRemove()
end

function s.postg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local g=eg:Filter(s.posfilter,nil,e,tp)

	if chkc then
		return g:IsContains(chkc)
	end

	if chk==0 then
		return #g>0
			and Duel.IsExistingMatchingCard(
				s.costfilter,tp,LOCATION_MZONE,0,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tg=g:Select(tp,1,1,nil)
	Duel.SetTargetCard(tg)
end
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc or not tc:IsRelateToEffect(e) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local rg=Duel.SelectMatchingCard(
		tp,
		s.costfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,1,
		nil
	)

	local rc=rg:GetFirst()

	if not rc then return end

	if Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)==0 then
		return
	end

	if tc:IsCanTurnSet() then
		Duel.ChangePosition(tc,POS_FACEDOWN_DEFENSE)
	end
end