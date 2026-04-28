--Right Eye of Light
local s,id=GetID()

s.CARD_BALDER = 13131331

function s.initial_effect(c)

	--------------------------------------------------
	-- Activate
	--------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--------------------------------------------------
	-- Activate from hand during opponent's turn
	--------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)
end

--------------------------------------------------
-- CONDITION (Balder on field or GY)
--------------------------------------------------

function s.balderfilter(c)
	return c:IsCode(s.CARD_BALDER) and c:IsFaceup()
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(function(c)
		return c:IsCode(s.CARD_BALDER)
	end,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil)
end

--------------------------------------------------
-- HAND ACTIVATION CONDITION
--------------------------------------------------

function s.handcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.GetTurnPlayer()~=tp
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,s.CARD_BALDER),
			tp,LOCATION_MZONE,0,1,nil)
end

--------------------------------------------------
-- TARGET + CHAIN LOCK
--------------------------------------------------

function s.stfilter(c)
	return c:IsFaceup() and c:IsSpellTrap()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.stfilter,tp,0,LOCATION_ONFIELD,nil)
	if chk==0 then return #g>0 end

	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,0,0)

	-- 🔥 FULL CHAIN LOCK (no one can respond)
	Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

--------------------------------------------------
-- OPERATION
--------------------------------------------------

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.stfilter,tp,0,LOCATION_ONFIELD,nil)
	local tc=g:GetFirst()

	while tc do
		-- Disable
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)

		-- Disable effects
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)

		tc=g:GetNext()
	end
end