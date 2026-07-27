--Limit Overdrive - Resonance
local s,id=GetID()

local KAZARI_ID=220450 -- Change to your Kazari card ID

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--Kazari filter
function s.cfilter(c)
	return c:IsCode(KAZARI_ID)
		and (c:IsFaceup() or c:IsLocation(LOCATION_MZONE))
		and c:IsReleasable()
end

--Cost
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE|LOCATION_SZONE,0,1,nil)
	end
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_MZONE|LOCATION_SZONE,0,1,99,nil)
	e:SetLabel(#g)
	Duel.Release(g,REASON_COST)
end

--Target
function s.tgfilter(c)
	return c:IsFaceup() and c:IsNegatable()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local ct=e:GetLabel()
	if chkc then
		return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD) and s.tgfilter(chkc)
	end
	if chk==0 then
		return ct>0
			and Duel.IsExistingTarget(s.tgfilter,tp,0,LOCATION_ONFIELD,ct,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,s.tgfilter,tp,0,LOCATION_ONFIELD,ct,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,g,#g,0,0)
end

--Operation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	for tc in aux.Next(tg) do
		if tc:IsFaceup() and tc:IsRelateToEffect(e) then
			--Negate its effects while it remains face-up
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD)
			tc:RegisterEffect(e1)

			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
		end
	end
end