local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Xyz summon procedure: 3+ Level 7 monsters
	Xyz.AddProcedure(c,nil,7,3)
	
	-- Cannot be destroyed by battle
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Change all monsters to Attack Position while in face-up Attack Position
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SET_POSITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetCondition(s.poscon)
	e2:SetTarget(s.postg)
	e2:SetValue(POS_FACEUP_ATTACK)
	c:RegisterEffect(e2)

	-- After damage calculation, if battled and "Limit Break!!!" activated, detach material, double ATK, extra attack (max 3 per turn)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DAMAGE_STEP_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(3,id)
	e3:SetCondition(s.atkcon)
	e3:SetCost(s.atkcost)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
	-- When sent to GY from anywhere, target 1 face-up card and return it to hand
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
	-- Activity counter to check "Limit Break!!!"
	Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,function(re) return not re:GetHandler():IsCode(220406) end)
end

function s.poscon(e)
	return e:GetHandler():IsAttackPos()
end
function s.postg(e,c)
	return true
end

function s.xyzfilter(c)
	return c:IsType(TYPE_XYZ) and c:IsSetCard(0xf86) and c:GetOverlayCount()>0 and c:IsFaceup()
end

function s.atkcon(e,tp)
	local c=e:GetHandler()
	return c:IsRelateToBattle()
		and Duel.GetCustomActivityCount(id,tp,ACTIVITY_CHAIN)>0
		and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then
		return g:IsExists(Card.CheckRemoveOverlayCard,1,nil,tp,1,REASON_COST)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVEXYZ)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	tc:RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.atkop(e,tp)
	local c=e:GetHandler()
	if not (c:IsFaceup() or c:IsAttackPos())  then return end
	-- double ATK
	local atk=c:GetAttack()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_ATTACK_FINAL)
	e1:SetValue(atk*2)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
	c:RegisterEffect(e1)
	-- extra attack
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetValue(c:GetAttackedCount())
	e2:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
	c:RegisterEffect(e2)
end



function s.limitfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xf86) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.limitfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.limitfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,s.limitfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
	local og=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,og,#og,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
		local g=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	end
end
