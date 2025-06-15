--Limit Break - Resonant Bond
local s,id=GetID()
function s.initial_effect(c)
	--Activate the turn it was Set if you control a "World Decoder" card
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e0:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e0:SetCondition(s.actcon)
	c:RegisterEffect(e0)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Choose effect once per turn
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetHintTiming(0,TIMING_END_PHASE)
	e2:SetTarget(s.target)
	e2:SetOperation(s.activate)
	c:RegisterEffect(e2)
end

function s.actcon(e)
	return Duel.IsExistingMatchingCard(s.wdfilter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end
function s.wdfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xb67) -- "World Decoder"
end

function s.tdfilter(c)
	return c:IsSetCard(0xb67) or c:IsSetCard(0xf86) and c:IsAbleToDeck() and not c:IsCode(id)
end

function s.posfilter(c)
	return c:IsFaceup() and c:IsCanTurnSet()
end

function s.setfilter(c,e,tp)
	return (c:IsSetCard(0xf86) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)))
		and not Duel.IsExistingMatchingCard(s.samefilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,c:GetCode())
		and c:IsSSetable()
end

function s.samefilter(c,code)
	return c:IsCode(code)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local opt=0
	local b1=Duel.IsExistingMatchingCard(s.posfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
		and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil,e,tp)

	if b1 and b2 then
		opt=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
	elseif b1 then
		opt=0 
	elseif b2 then
		opt=1
	else
		return false
	end
	if opt==0 then
		local g=Duel.SelectTarget(tp,s.posfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	end
	e:SetLabel(opt)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local opt=e:GetLabel()
	if opt==0 then
		--Face-down a monster
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g1=Duel.GetFirstTarget()
		if g1 then
			local g2=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
			if #g2>0 and Duel.SendtoDeck(g2,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
				Duel.ChangePosition(g1,POS_FACEDOWN_DEFENSE)
			end
		end
	elseif opt==1 then
		--Set from Deck
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SSet(tp,g:GetFirst())
			--Cannot be activated this turn
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_CANNOT_ACTIVATE)
			e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
			e1:SetTargetRange(LOCATION_SZONE,0)
			e1:SetTarget(function(e,c)
				return c:IsCode(g:GetFirst():GetCode())
			end)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end
end
