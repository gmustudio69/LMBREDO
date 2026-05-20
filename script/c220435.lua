local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	-- Also activate for Summon negation
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON)
	c:RegisterEffect(e2)
end

-- Level 13 Synchro check
function s.lv13filter(c)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsLevel(13)
end

-- Activation condition
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetCurrentChain()==0 then return false end
	local res=false
	if re:IsActiveType(TYPE_MONSTER) and re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
		if tg and tg:IsExists(Card.IsControler,1,nil,tp) then res=true end
	end
	return (re:IsHasType(EFFECT_TYPE_ACTIVATE) or res) and Duel.IsChainNegatable(ev)
end

-- Xyz material filter
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xf86) and c:IsType(TYPE_XYZ) and c:CheckRemoveOverlayCard(tp,1,REASON_COST)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.lv13filter,tp,LOCATION_MZONE,0,1,nil)
	if chk==0 then return b1 or b2 end
	
	if b1 and (not b2 or Duel.SelectYesNo(tp,aux.Stringid(id,0))) then
		local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
		g:GetFirst():RemoveOverlayCard(tp,1,1,REASON_COST)
	end
	-- If b2 is true and we don't pick b1, we proceed without cost
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end