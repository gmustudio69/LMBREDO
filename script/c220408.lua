--Limit Break - Disaster
local s,id=GetID()
function s.initial_effect(c)
	--Negate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	--Graveyard effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end

--Condition for negation
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsChainNegatable(ev)
end

--Cost: detach 1 from a Limit Breaker Xyz, unless you control Level 13 Synchro
function s.cfilter(c,tp)
	return c:IsType(TYPE_XYZ) and c:IsSetCard(0xf86) and c:CheckRemoveOverlayCard(tp,1,REASON_COST)
end
function s.synfilter(c)
	return c:IsType(TYPE_SYNCHRO) and c:IsLevel(13)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil)
	if chk==0 then return b1 or b2 end
	local op=nil
	if b1 and b2 then
		op=Duel.SelectEffect(tp,
			{b1,aux.Stringid(id,0)},
			{b2,aux.Stringid(id,1)})
	else
		op=(b1 and 1) or (b2 and 2)
	end
	if op==1 then
		local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_MZONE,0,1,1,nil)
		g:GetFirst():RemoveOverlayCard(tp,1,1,REASON_COST)
	elseif op==2 then
		return
	end
end

--Negate & destroy
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

--Graveyard effect
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
		and Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_EXTRA,0,1,nil,TYPE_XYZ) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local g=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_EXTRA,0,nil,TYPE_XYZ)
	if #g==0 or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local tg=g:Select(tp,1,1,nil):GetFirst()
	if Duel.SendtoGrave(tg,REASON_EFFECT)~=0 and tg:IsLocation(LOCATION_GRAVE) then
		local atk=math.floor(tc:GetBaseAttack()/2)
		if atk>0 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(atk)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
end
