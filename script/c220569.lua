--Lawrence's Pyrea
local s,id=GetID()
function s.initial_effect(c)
	--Activate
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

	--Quick Effect: Destroy 1 FIRE monster with 0 DEF from Deck or face-up field
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	--Give control of 1 "Detonator" monster, then destroy adjacent cards
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_CONTROL+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.ctltg)
	e3:SetOperation(s.ctlop)
	c:RegisterEffect(e3)
end

-- 1. Placement Trigger functions
function s.placecon(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_EFFECT)~=0
end
function s.placetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end
function s.placeop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		-- Moves the continuous trap back onto the field face-up
		Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end

-- 2. Quick Effect Destruction functions
function s.desfilter(c)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsDefense(0) and c:IsDestructable()
		and (c:IsLocation(LOCATION_DECK) or c:IsFaceup())
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_DECK|LOCATION_MZONE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_DECK|LOCATION_MZONE)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_DECK|LOCATION_MZONE,0,1,1,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- 3. Control Change + Proximity Blast functions
function s.ctlfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc25) -- Assuming custom archetype code 0x990 for "Detonator"
		and c:IsControlerCanBeChanged()
end
function s.ctltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.ctlfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,tp,LOCATION_MZONE)
end
function s.ctlop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectMatchingCard(tp,s.ctlfilter,tp,LOCATION_MZONE,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.HintSelection(g)
		-- Hand control over to the opponent
		if Duel.GetControl(tc,1-tp) then
			-- Get its new zone layout position relative to your opponent's side
			local seq=tc:GetSequence()
			if seq>4 then return end -- Avoid bugs with extra monster zones
			
			local zone_mask=0
			-- Check left adjacent zone
			if seq>0 then zone_mask = zone_mask | (1 << (seq-1)) end
			-- Check right adjacent zone
			if seq<4 then zone_mask = zone_mask | (1 << (seq+1)) end
			
			-- Find both monster zone neighbors and corresponding backrow spaces directly behind them
			local dg=Duel.GetMatchingGroup(nil,1-tp,LOCATION_MZONE|LOCATION_SZONE,0,nil)
			local des_group=Group.CreateGroup()
			
			for dc in aux.Next(dg) do
				local dseq=dc:GetSequence()
				-- Filter items matching left/right sequence indicators
				if dseq<=4 and (zone_mask & (1 << dseq)) ~= 0 then
					des_group:AddCard(dc)
				-- Match Spell & Trap Zone directly behind the target monster
				elseif dc:IsLocation(LOCATION_SZONE) and dseq==seq then
					des_group:AddCard(dc)
				end
			end
			
			if #des_group>0 then
				Duel.BreakEffect()
				Duel.Destroy(des_group,REASON_EFFECT)
			end
		end
	end
end