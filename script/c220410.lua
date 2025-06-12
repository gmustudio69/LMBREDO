--<Limit Breaker> Ouroboros
local s,id,o=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Must be Special Summoned by "Limit Break"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(function(e,se,sp,st)
		return se and se:IsActiveType(TYPE_SPELL+TYPE_TRAP) and se:GetHandler():IsSetCard(0xf86)
	end)
	c:RegisterEffect(e0)
	-- Cannot be destroyed by card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.rmtarget)
	e2:SetTargetRange(0,LOCATION_ONFIELD)
	e2:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_REMOVE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetTarget(s.mttg)
	e3:SetOperation(s.mtop)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCost(s.cpcost)
	e4:SetTarget(s.cptg)
	e4:SetCondition(s.qcon)
	e4:SetOperation(s.cpop)
	c:RegisterEffect(e4)
end
function s.ellie(c)
	return c:IsFaceup() and c:IsCode(220405)
end
function s.qcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsExistingMatchingCard(s.ellie,tp,LOCATION_ONFIELD,0,1,nil)
end
function s.rmtarget(e,c)
	return Duel.IsPlayerCanRemove(e:GetHandlerPlayer(),c)
end
function s.cfilter(c,e)
	return c:GetOwner()~=e:GetHandlerPlayer() and c:IsLocation(LOCATION_REMOVED) 
end
function s.mttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return eg:IsContains(chkc) end
	if chk==0 then return eg:IsExists(s.cfilter,1,nil,e) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=eg:FilterSelect(tp,s.cfilter,1,1,nil,e)
	Duel.SetTargetCard(g)
end
function s.mtop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		Duel.Overlay(c,Group.FromCards(tc))
	end
end
function s.cpfilter(c)
	return c:IsNormalSpell() and c:IsAbleToRemove() and c:CheckActivateEffect(true,true,false)~=nil
end
function s.cpcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end
function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		local te=e:GetLabelObject():GetFirst():CheckActivateEffect(true,true,false)
		local tg=te:GetTarget()
		return tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
	end
	if chk==0 then return Duel.IsExistingTarget(s.cpfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local tc=Duel.SelectTarget(tp,s.cpfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil):GetFirst()
	e:SetLabelObject(tc)
	local te=tc:CheckActivateEffect(true,true,false)
	e:SetProperty(EFFECT_FLAG_CARD_TARGET|te:GetProperty())
	local tg=te:GetTarget()
	if tg then
		tg(e,tp,eg,ep,ev,re,r,rp,1)
	end
	Duel.ClearOperationInfo(0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,tc,1,tp,0)
end
function s.cpop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if not tc:IsRelateToEffect(e) or Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)==0 then return end
	local te=tc:CheckActivateEffect(true,true,false)
	if not te then return end
	local op=te:GetOperation()
	if op then op(e,tp,eg,ep,ev,re,r,rp) end
end