--Red-Eyes Rising Metal Dragon
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,nil,8,3,s.ovfilter,aux.Stringid(id,0),1,s.xyzop)
	

	-- Indestructible by card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Burn when opponent activates a card/effect (while has material)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVED)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.burncon)
	e2:SetOperation(s.burnop)
	c:RegisterEffect(e2)

	-- Quick Effect: Detach 1 → destroy card/effect on field, burn if monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.descon)
	e3:SetCost(s.descost)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- Alternative Xyz Summon condition: Using Red-Eyes Flare Metal Dragon
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsSummonCode(lc,SUMMON_TYPE_XYZ,tp,44405066)
end
function s.xyzop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
	return true
end

-- Burn 600 if opponent activates effect while this card has material
function s.burncon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and e:GetHandler():GetOverlayCount()>0
end
function s.burnop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Damage(1-tp,600,REASON_EFFECT)
end

-- Quick effect: destroy card activated on field
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return re:IsHasProperty(EFFECT_FLAG_CARD_TARGET)
		or (re:GetHandler():IsOnField() and rp==1-tp)
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return re:GetHandler():IsDestructable() end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,re:GetHandler(),1,0,0)
	if re:GetHandler():IsMonster() then
		Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,re:GetHandler():GetAttack())
	end
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if rc:IsRelateToEffect(re) and Duel.Destroy(rc,REASON_EFFECT)>0 and rc:IsMonster() then
		local atk=math.max(rc:GetAttack(),0)
		Duel.Damage(1-tp,atk,REASON_EFFECT)
	end
end
