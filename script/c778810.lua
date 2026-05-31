local s,id=GetID()

function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	-- Protect Moon Gate
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.reptg)
	c:RegisterEffect(e2)

	-- Negate attack from GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,3})
	e3:SetCost(aux.bfgcost)
	e3:SetCondition(s.atkcon)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
end

-------------------------------------------------
-- Moon Gate
-------------------------------------------------

function s.mgfilter(c)
	return c:IsFaceup() and c:IsCode(778804)
end

function s.mgplacefilter(c,tp)
	return c:IsCode(778804) and not Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_FZONE,0,1,nil,778804)
end

-------------------------------------------------
-- Mysthisch
-------------------------------------------------

function s.thfilter(c)
	return c:IsSetCard(0x76b)
		and c:IsMonster()
		and c:IsAbleToHand()
end

-------------------------------------------------
-- Activation
-------------------------------------------------

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)

	local hasgate=Duel.IsExistingMatchingCard(
		s.mgfilter,tp,LOCATION_FZONE,0,1,nil)

	local b1=not hasgate and (
		Duel.IsExistingMatchingCard(
			s.mgplacefilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,tp)
	)

	local b2=hasgate and Duel.IsExistingMatchingCard(
		s.thfilter,tp,LOCATION_DECK,0,1,nil)

	if not (b1 or b2) then return end

	local op

	if b1 and b2 then
		op=Duel.SelectOption(
			tp,
			aux.Stringid(id,2),
			aux.Stringid(id,3)
		)
	elseif b1 then
		op=0
	else
		op=1
	end

	--------------------------------------------------
	-- Place Moon Gate
	--------------------------------------------------
	if op==0 then

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)

		local g=Duel.SelectMatchingCard(
			tp,
			s.mgplacefilter,
			tp,
			LOCATION_DECK+LOCATION_GRAVE,
			0,
			1,1,nil,tp
		)

		local tc=g:GetFirst()

		if tc then
			Duel.MoveToField(
				tc,
				tp,tp,
				LOCATION_FZONE,
				POS_FACEUP,
				true
			)
		end

	--------------------------------------------------
	-- Search Mysthich
	--------------------------------------------------
	else

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

		local g=Duel.SelectMatchingCard(
			tp,
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,1,nil
		)

		local tc=g:GetFirst()

		if tc then
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)
		end
	end
end
-------------------------------------------------
-- Destroy substitute
-------------------------------------------------

function s.reptg(e,c)
	return c:IsFaceup()
		and c:IsCode(778804)
		and c:IsReason(REASON_EFFECT)
end

-------------------------------------------------
-- Attack negate
-------------------------------------------------

function s.atkfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x76b)
		or c:IsFacedown()
end

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetAttackTarget()

	return tc
		and tc:IsControler(tp)
		and (
			tc:IsFacedown()
			or (tc:IsFaceup() and tc:IsSetCard(0x76b))
		)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateAttack()
end