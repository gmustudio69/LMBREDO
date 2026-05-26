--<Limit Breaker> Ouroboros
local s,id,o=GetID()
function s.initial_effect(c)
	-- Must be Special Summoned by "Limit" S/T
	c:EnableReviveLimit()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetValue(s.splimit)
	c:RegisterEffect(e1)
	-- Banisher (Field to GY -> Banish)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.rmtarget)
	e2:SetTargetRange(0,LOCATION_ONFIELD)
	e2:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e2)

	-- Attach banished card
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_REMOVE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCost(s.mtcost)
	e3:SetTarget(s.mttg)
	e3:SetOperation(s.mtop)
	c:RegisterEffect(e3)

	-- 3: Quick Effect while controlling Ellie: Copy "Limit" Spell
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCountLimit(1)
	e4:SetCondition(s.elliecon)
	e4:SetTarget(s.copytg)
	e4:SetOperation(s.copyop)
	c:RegisterEffect(e4)
	-- Banish instead of GY (Field or Detached)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_RANGE)
	e5:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(0,LOCATION_GRAVE)
	e5:SetValue(LOCATION_REMOVED)
	e5:SetTarget(s.detachtarget)
	c:RegisterEffect(e5)
end

-- E1: Special Summon Limit
function s.splimit(e,se,sp,st)
	return se:GetHandler():IsSetCard(0xf86) -- Replace 0xXXXX with your "Limit" SetCode
end
function s.detachtarget(e,c,tp,r)
	return c:GetOwner()~=e:GetHandlerPlayer() and c:GetReason()&(REASON_COST+REASON_EFFECT)~=0
end
function s.rmtarget(e,c)
	return Duel.IsPlayerCanRemove(e:GetHandlerPlayer(),c)
end
function s.filter(c,e)
	return c:GetOwner()~=e:GetHandlerPlayer() and c:IsLocation(LOCATION_REMOVED) 
end
function s.mtcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetFlagEffect(id)==0 and c:IsType(TYPE_XYZ) end
	c:RegisterFlagEffect(id,RESET_CHAIN,0,1)
end
function s.mttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return eg:IsContains(chkc) end
	if chk==0 then return eg:IsExists(s.filter,1,nil,e) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=eg:FilterSelect(tp,s.filter,1,1,nil,e)
	Duel.SetTargetCard(g)
end
function s.mtop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		Duel.Overlay(c,Group.FromCards(tc))
	end
end

-- E4/E5: Ellie Condition
function s.elliecon(e)
	return Duel.IsExistingMatchingCard(Card.IsCode,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil,220405)
end
-- E5: Copy "Limit" Spell
function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end
function s.copyfilter(c,e,tp,eg,ep,ev,re,r,rp)
	if not (c:IsSetCard(0xf86) and c:IsType(TYPE_SPELL) and c:IsAbleToRemove()) then return false end
	-- Ensure the spell has an activatable effect we can copy (bypassing cost)
	local te=c:CheckActivateEffect(false,true,false)
	if not te then return false end
	-- Ensure we have 2 materials to detach later
	if e:GetHandler():GetOverlayCount()<2 then return false end
	return true
end
function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		local te=e:GetLabelObject()
		local tg=te and te:GetTarget() or nil
		return tg and tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
	end
	if chk==0 then return Duel.IsExistingTarget(s.copyfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp,eg,ep,ev,re,r,rp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	-- Target the Spell first
	local g=Duel.SelectTarget(tp,s.copyfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp,eg,ep,ev,re,r,rp)
	local tc=g:GetFirst()
	local te,ceg,cep,cev,cre,cr,crp=tc:CheckActivateEffect(false,true,true)
	e:SetLabelObject(te)
	
	-- If the copied effect also targets, allow the player to select those targets now
	local tg=te:GetTarget()
	if tg then tg(e,tp,ceg,cep,cev,cre,cr,crp,1) end
	Duel.ClearOperationInfo(0)
end
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- Find the "Limit" Spell we originally targeted
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	if not g then return end
	local tc=g:Filter(Card.IsType,nil,TYPE_SPELL):GetFirst()
	
	-- Banish it and Detach 2
	if tc and tc:IsRelateToEffect(e) and Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)>0 then
		if c:CheckRemoveOverlayCard(tp,2,REASON_EFFECT) then
			Duel.BreakEffect()
			c:RemoveOverlayCard(tp,2,2,REASON_EFFECT)
			
			-- Apply the effect
			local te=e:GetLabelObject()
			if te then
				local op=te:GetOperation()
				if op then op(e,tp,eg,ep,ev,re,r,rp) end
			end
		end
	end
end