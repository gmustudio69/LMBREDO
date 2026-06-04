local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon procedure
	c:EnableReviveLimit()
	--Pendulum.AddProcedure(c)
	Link.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_EFFECT),2,2)

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EFFECT_REPLACE_DISCARD)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTarget(s.reptg)
	e1:SetValue(s.repval)
	e1:SetOperation(s.repop)
	c:RegisterEffect(e1)

	-- Monster Effect 1: Trigger on Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id+100)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	
	-- Monster Effect 2: Same trigger when summoned to a linked zone
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.linkcon)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Monster Effect 3: If sent to Extra Deck face-up, place in Pendulum Zone
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_TO_DECK)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,id+200)
	e4:SetTarget(s.pzontg)
	e4:SetOperation(s.pzonop)
	c:RegisterEffect(e4)
end

-- Pendulum Effect Logic
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDestructable() end
	return true
end

function s.repval(e,c)
	return true
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT+REASON_REPLACE)
end

-- Monster Effect Logic
function s.linkcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c,lc) return lc:GetLinkedGroup():IsContains(c) end,1,nil,e:GetHandler())
end
-- Fix 1: Targeting Logic in Monster Effect
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	-- We need 1 monster I control AND 1 other card on the field
	if chk==0 then 
		return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingTarget(function(c,ec) return c~=ec end,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,e:GetHandler()) 
	end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	-- Ensure the second target is not the first target
	local g2=Duel.SelectTarget(tp,function(c,tc) return c~=tc end,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,g1:GetFirst(),g1:GetFirst())
	
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g1,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Get the target group
	local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	-- 2. Filter for cards that are still on the field and related to the effect
	local g=tg:Filter(Card.IsRelateToEffect,nil,e)
	
	if #g < 2 then return end

	-- 3. Ask player to pick 1 to Destroy
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	tc1 = g:GetFirst()
	tc2 = g:GetNext()
	
	-- 5. Perform actions
	if tc1 and Duel.Destroy(tc1,REASON_EFFECT)>0 and tc2 then
		-- This uses the standard way to banish until End Phase
		Duel.Remove(tc2,POS_FACEUP,REASON_EFFECT+REASON_TEMPORARY)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetCountLimit(1)
		e1:SetLabel(Duel.GetTurnCount())
		e1:SetLabelObject(tc)
		if Duel.IsPhase(PHASE_END) and Duel.IsTurnPlayer(1-tp) then
			e1:SetLabel(Duel.GetTurnCount())
			e1:SetReset(RESETS_STANDARD_PHASE_END|RESET_OPPO_TURN,2)
		else
			e1:SetLabel(0)
			e1:SetReset(RESETS_STANDARD_PHASE_END|RESET_OPPO_TURN)
		end
		e1:SetCondition(s.retcon)
		e1:SetOperation(s.retop)
		Duel.RegisterEffect(e1,tp)
	end
end
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	return Duel.GetTurnCount()~=e:GetLabel() and Duel.IsTurnPlayer(1-tp)
		and tc and tc:GetReasonEffect() and tc:GetReasonEffect():GetHandler()==e:GetHandler()
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ReturnToField(e:GetLabelObject())
end
-- Extra Deck to Pendulum Zone Logic
function s.pzontg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1) end
end
function s.pzonop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)) then return end
	Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	local e1=Effect.CreateEffect(c)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetValue(TYPE_SPELL+TYPE_LINK)
	c:RegisterEffect(e1)
end