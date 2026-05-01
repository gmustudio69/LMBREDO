--Limit Breaker - Code Zero
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,800) end
	Duel.PayLPCost(tp,800)
end
-- Filter for "Limit" Spell that has an activatable effect
function s.filter(c,e,tp,eg,ep,ev,re,r,rp)
	if not (c:IsSetCard(0xf86) and c:IsType(TYPE_SPELL) and c:IsAbleToRemove()) then return false end
	local te=c:CheckActivateEffect(false,true,false)
	return te~=nil
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		-- Pass the targeting condition to the copied spell if it targets
		local te=e:GetLabelObject()
		local tg=te and te:GetTarget() or nil
		return tg and tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
	end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_GRAVE,0,1,nil,e,tp,eg,ep,ev,re,r,rp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	
	-- Target the "Limit" spell
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp,eg,ep,ev,re,r,rp)
	local tc=g:GetFirst()
	
	-- Extract the spell's effect and prompt for its targets (if any)
	local te,ceg,cep,cev,cre,cr,crp=tc:CheckActivateEffect(false,true,true)
	
	-- Merge properties to ensure we don't lose the CARD_TARGET flag
	e:SetProperty(te:GetProperty()|EFFECT_FLAG_CARD_TARGET)
	e:SetLabelObject(te)
	
	local tg=te:GetTarget()
	if tg then tg(e,tp,ceg,cep,cev,cre,cr,crp,1) end
	
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	if not te then return end
	local tc=te:GetHandler()
	
	-- Banish the targeted spell
	if tc:IsRelateToEffect(e) and Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)>0 then
		-- If successfully banished, apply the spell's effect
		local op=te:GetOperation()
		if op then 
			Duel.BreakEffect()
			op(e,tp,eg,ep,ev,re,r,rp) 
		end
	end
end
