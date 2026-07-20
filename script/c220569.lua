
local s,id=GetID()
function s.initial_effect(c)
	--Activate Card
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--If destroyed by card effect: Place face-up in Spell & Trap Zone
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_DESTROYED)
	e1:SetCondition(s.placecon)
	e1:SetTarget(s.placetg)
	e1:SetOperation(s.placeop)
	c:RegisterEffect(e1)

	--Quick Effect: Activate 1 of 2 options
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_CONTROL)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end

-- 1. Destruction Placement Functions
function s.placecon(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_EFFECT)~=0
end

function s.placetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end

function s.placeop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end

-- 2. Choice Selection Filters
function s.desfilter(c)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsDefense(0) and c:IsDestructable()
		and (c:IsLocation(LOCATION_DECK) or c:IsFaceup())
end

function s.ctrlfilter(c)
	return c:IsSetCard(0xc25) -- Assuming 0x98a is the "Detonator" archetype string ID
		and c:IsFaceup() and c:IsControlerCanBeChanged()
end

-- Target logic handling the split choices
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.ctrlfilter,tp,LOCATION_MZONE,0,1,nil) 
		and Duel.GetLocationCount(1-tp,LOCATION_MZONE,tp)>0

	if chk==0 then return b1 or b2 end

	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,3))+1
	end

	e:SetLabel(op)
	if op==0 then
		e:SetCategory(CATEGORY_DESTROY)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE)
	else
		e:SetCategory(CATEGORY_CONTROL+CATEGORY_DESTROY)
		Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,tp,LOCATION_MZONE)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_ONFIELD)
	end
end

-- Execution Logic
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==0 then
		-- Option 1: Destroy 1 FIRE monster with 0 DEF from Deck or Field
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE,0,1,1,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	else
		-- Option 2: Give control of 1 "Detonator" monster, then destroy adjacent cards
		if Duel.GetLocationCount(1-tp,LOCATION_MZONE,tp)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
		local g=Duel.SelectMatchingCard(tp,s.ctrlfilter,tp,LOCATION_MZONE,0,1,1,nil)
		local tc=g:GetFirst()
		if not tc then return end

		-- Swap control of the monster to opponent
		if Duel.GetControl(tc,1-tp) then
			-- Collect adjacent card slots from the monster's new perspective position
			local sequence=tc:GetSequence()
			local controller=tc:GetControler()
			local dg=Group.CreateGroup()

			-- Left adjacent Monster Zone check
			if sequence>0 and sequence<5 then
				local lc=Duel.GetFieldCard(controller,LOCATION_MZONE,sequence-1)
				if lc then dg:AddCard(lc) end
			end
			-- Right adjacent Monster Zone check
			if sequence>=0 and sequence<4 then
				local rc=Duel.GetFieldCard(controller,LOCATION_MZONE,sequence+1)
				if rc then dg:AddCard(rc) end
			end
			-- Behind Spell & Trap Zone check 
			if sequence>=0 and sequence<=4 then
				local sc=Duel.GetFieldCard(controller,LOCATION_SZONE,sequence)
				if sc then dg:AddCard(sc) end
			end

			-- Clean filter to group only destructible objects remaining
			local des_group=dg:Filter(Card.IsDestructable,nil)
			if #des_group>0 then
				Duel.BreakEffect()
				Duel.Destroy(des_group,REASON_EFFECT)
			end
		end
	end
end