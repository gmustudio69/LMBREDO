local s,id=GetID()
function s.initial_effect(c)
	aux.AddEquipProcedure(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- Equip limit: Any monster
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EQUIP_LIMIT)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetValue(1) -- Allows any monster
	c:RegisterEffect(e2)

	-- Granted Effects (Conditional on Warrior)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e3:SetValue(ATTRIBUTE_DARK)
	e3:SetCondition(function(e) return e:GetHandler():GetEquipTarget():IsRace(RACE_WARRIOR) end)
	c:RegisterEffect(e3)

	-- Granted Effect: Gain the "Take Control" ability
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e4:SetCondition(function(e,c) return e:GetHandler():GetEquipTarget()==c and c:IsRace(RACE_WARRIOR) end)
	e4:SetLabelObject(e7)
	c:RegisterEffect(e4)
	local e9=e4:Clone()
	e9:SetLabelObject(e8)
	c:RegisterEffect(e9)
	-- GY Effect: Re-equip
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_EQUIP)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_TO_GRAVE) -- Note: See below for multi-trigger
	e5:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e5:SetCountLimit(1,id)
	e5:SetTarget(s.eqtg)
	e5:SetOperation(s.eqop)
	c:RegisterEffect(e5)
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,0))
	e7:SetType(EFFECT_TYPE_IGNITION) -- Default to Ignition
	e7:SetRange(LOCATION_MZONE)
	e7:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e7:SetCountLimit(1)
	-- Logic to turn into Quick Effect based on condition
	e7:SetTarget(s.controltg)
	e7:SetOperation(s.controlop)
	c:RegisterEffect(e7)
	local e8=e7:Clone()
	e8:SetType(EFFECT_TYPE_QUICK_O)
	e8:SetCode(EVENT_FREE_CHAIN)
	e8:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e8:SetCondition(s.quickcon)
	c:RegisterEffect(e8)
end
-- Define the effect to be granted to the monster
function s.gain_effect(e,c)
	
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if e:GetHandler():IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Equip(tp,e:GetHandler(),tc)
	end
end
-- Condition to toggle Quick Effect
function s.quickcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(function(c) 
		return c:IsSummonLocation(LOCATION_EXTRA) and not c:IsAttribute(ATTRIBUTE_DARK) 
	end,tp,0,LOCATION_MZONE,1,nil)
end
function s.controltg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsControlerCanBeChanged() end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(function(c) return c:IsFaceup() and not c:IsAttribute(ATTRIBUTE_DARK) end,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
   
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end
function s.controlop(e,tp,eg,ep,ev,re,r,rp)
	local tc= Duel.SelectMatchingCard(tp,function(c) return c:IsFaceup() and not c:IsAttribute(ATTRIBUTE_DARK) end,tp,0,LOCATION_MZONE,1,1,nil):GetFirst()
	if tc and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		if Duel.GetControl(tc,tp) then
				-- Negate effects
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
			-- Attribute to DARK
			local e3=e1:Clone()
			e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
			e3:SetValue(ATTRIBUTE_DARK)
			tc:RegisterEffect(e3)
			-- Level to 7
			if tc:HasLevel() then
				local e4=e1:Clone()
				e4:SetCode(EFFECT_CHANGE_LEVEL)
				e4:SetValue(7)
				tc:RegisterEffect(e4)
			end
		end
	end
end

-- GY Re-Equip
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsRace(RACE_WARRIOR) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if e:GetHandler():IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Equip(tp,e:GetHandler(),tc)
	end
end