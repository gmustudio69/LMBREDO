local s,id=GetID()
function s.initial_effect(c)
	aux.AddEquipProcedure(c)
	-- Granted Effects (Conditional on Warrior)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e1:SetValue(ATTRIBUTE_DARK)
	e1:SetCondition(function(e) return e:GetHandler():GetEquipTarget():IsRace(RACE_WARRIOR) end)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION) -- Default to Ignition
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1)
	-- Logic to turn into Quick Effect based on condition
	e2:SetTarget(s.controltg)
	e2:SetOperation(s.controlop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetCondition(s.quickcon)
	c:RegisterEffect(e3)
	--Grant the above effects to a "DoomZ" monster equipped with this card
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e4:SetTarget(function(e,c) return e:GetHandler():GetEquipTarget()==c and c:IsRace(RACE_WARRIOR) end)
	e4:SetLabelObject(e2)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetLabelObject(e3)
	c:RegisterEffect(e5)
	-- GY Effect: Re-equip
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_EQUIP)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_TO_GRAVE) -- Note: See below for multi-trigger
	e5:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e5:SetCountLimit(1,{id,1})
	e5:SetTarget(s.eqtg)
	e5:SetOperation(s.eqop)
	c:RegisterEffect(e5)
	local e6=e5:Clone()
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O) 
	e6:SetCode(EVENT_SPSUMMON_SUCCESS)
	e6:SetProperty(EFFECT_FLAG_DELAY,EFFECT_FLAG2_CHECK_SIMULTANEOUS)
	e6:SetRange(LOCATION_GRAVE)
	e6:SetCondition(s.eqcon)
	c:RegisterEffect(e6)
end
function s.eqconfilter(c,tp)
	return c:IsRace(RACE_WARRIOR) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsLevel(7) or c:IsRank(7) and c:IsSummonPlayer(tp) and c:IsFaceup()
end
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.eqconfilter,1,nil,tp)
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
function s.eqfilter(c,e)
return c:IsRace(RACE_WARRIOR)
end
-- GY Re-Equip
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsRace(RACE_WARRIOR) end
	if chk==0 then return Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if e:GetHandler():IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Equip(tp,e:GetHandler(),tc)
	end
end