local s,id=GetID()

function s.initial_effect(c)

	--------------------------------------------------
	-- Can activate the turn it was Set
	--------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e1:SetCondition(s.actcon)
	c:RegisterEffect(e1)

	--------------------------------------------------
	-- Banish face-down monster
	--------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.target)
	e2:SetOperation(s.activate)
	c:RegisterEffect(e2)

	--------------------------------------------------
	-- GY LP gain
	--------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.reccon)
	e3:SetCost(aux.bfgcost)
	e3:SetTarget(s.rectg)
	e3:SetOperation(s.recop)
	c:RegisterEffect(e3)
end

--------------------------------------------------
-- Moon Gate
--------------------------------------------------

function s.actcon(e)
	return Duel.IsExistingMatchingCard(
		s.mgfilter,
		e:GetHandlerPlayer(),
		LOCATION_FZONE,
		0,
		1,
		nil
	)
end

function s.mgfilter(c)
	return c:IsFaceup()
		and c:IsCode(778804)
end

--------------------------------------------------
-- Effect 1
--------------------------------------------------

function s.fdfilter(c)
	return c:IsFacedown()
		and c:IsMonster()
		and c:IsAbleToRemove()
end

function s.otherfilter(c,tc)
	return c~=tc
		and c:IsAbleToRemove()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsFacedown()
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.fdfilter,
			tp,
			LOCATION_MZONE,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectTarget(
		tp,
		s.fdfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		1,1,nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		g,
		1,
		0,
		0
	)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)

	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e) then
		return
	end

	local own=tc:IsControler(tp)

	if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)==0 then
		return
	end

	if not own then return end

	if not Duel.IsExistingMatchingCard(
		s.otherfilter,
		tp,
		LOCATION_ONFIELD,
		LOCATION_ONFIELD,
		1,
		tc,
		tc
	) then
		return Duel.SelectYesNo(tp,aux.Stringid(id,0))
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.otherfilter,
		tp,
		LOCATION_ONFIELD,
		LOCATION_ONFIELD,
		1,1,
		tc,
		tc
	)

	if #g>0 then
		Duel.Remove(
			g,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end

--------------------------------------------------
-- Effect 2
--------------------------------------------------

function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLP(1-tp)>Duel.GetLP(tp)
end

function s.recfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x76b)
		and c:IsMonster()
		and c:GetOriginalAttack()>0
end

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsControler(tp)
			and s.recfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.recfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)

	local g=Duel.SelectTarget(
		tp,
		s.recfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,1,nil
	)

	local tc=g:GetFirst()

	Duel.SetOperationInfo(
		0,
		CATEGORY_RECOVER,
		nil,
		0,
		tp,
		tc:GetOriginalAttack()
	)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)

	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup() then
		return
	end

	local atk=tc:GetOriginalAttack()

	if atk<0 then atk=0 end

	Duel.Recover(tp,atk,REASON_EFFECT)
end