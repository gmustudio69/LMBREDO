local s,id=GetID()

function s.initial_effect(c)

	--------------------------------------------------
	-- Activate
	--------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--------------------------------------------------
	-- Opponent monsters lose ATK
	--------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(0,LOCATION_MZONE)
	e1:SetValue(s.val)
	c:RegisterEffect(e1)

	--------------------------------------------------
	-- Opponent monsters lose DEF
	--------------------------------------------------
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)

	--------------------------------------------------
	-- Negate Spell/Trap
	--------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_SZONE)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	--------------------------------------------------
	-- Revive effect
	--------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCost(aux.bfgcost)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

--------------------------------------------------
-- ATK / DEF reduction
--------------------------------------------------

function s.val(e,c)
	return Duel.GetMatchingGroupCount(
		Card.IsAbleToRemove,
		e:GetHandlerPlayer(),
		LOCATION_REMOVED,
		0,
		nil
	)*-100
end

--------------------------------------------------
-- Moon Gate
--------------------------------------------------

function s.mgfilter(c)
	return c:IsFaceup() and c:IsCode(778804)
end

--------------------------------------------------
-- Negate
--------------------------------------------------

function s.costfilter(c)
	return c:IsCode(778803)
		and c:IsAbleToRemoveAsCost()
		and (c:IsLocation(LOCATION_HAND)
			or c:IsLocation(LOCATION_MZONE))
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
		and Duel.IsChainNegatable(ev)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.costfilter,
			tp,
			LOCATION_HAND+LOCATION_MZONE,
			0,
			1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.costfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE,
		0,
		1,1,nil)

	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)

	if re:GetHandler():IsAbleToRemove() then
		Duel.SetOperationInfo(
			0,
			CATEGORY_REMOVE,
			Group.FromCards(re:GetHandler()),
			1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)

	if Duel.NegateActivation(ev)
		and Duel.IsExistingMatchingCard(
			s.mgfilter,tp,
			LOCATION_FZONE,
			LOCATION_FZONE,
			1,nil)
		and re:GetHandler():IsRelateToEffect(re)
		and re:GetHandler():IsAbleToRemove() then

		Duel.Remove(
			re:GetHandler(),
			POS_FACEUP,
			REASON_EFFECT)
	end
end

--------------------------------------------------
-- Revive
--------------------------------------------------

function s.spfilter(c,e,tp)
	return c:IsSetCard(0x76b)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(
			e,0,tp,false,false)
end

function s.rmfilter(c)
	return c:IsMonster()
		and c:IsAbleToRemove()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,tp,
				LOCATION_GRAVE+LOCATION_REMOVED,
				0,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(
				s.rmfilter,tp,
				LOCATION_MZONE,0,
				1,nil)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,1,tp,
		LOCATION_GRAVE+LOCATION_REMOVED)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,1,tp,
		LOCATION_MZONE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		1,1,nil,e,tp)

	local tc=g:GetFirst()

	if not tc then return end

	if Duel.SpecialSummon(
		tc,
		0,tp,tp,
		false,false,
		POS_FACEUP)==0 then
		return
	end

	local rg=Duel.GetMatchingGroup(
		s.rmfilter,tp,
		LOCATION_MZONE,0,
		tc)

	if #rg==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local sg=rg:Select(tp,1,1,nil)

	Duel.Remove(
		sg,
		POS_FACEUP,
		REASON_EFFECT)
end