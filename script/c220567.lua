--Custom Spell Card
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	--Continuous: Protection for FIRE Warrior monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.subtg)
	e2:SetValue(s.subval)
	c:RegisterEffect(e2)

	--Ignition: Destroy & Skip Time
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- 1. Destruction Replacement Filters
function s.subtg(e,c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR)
end
function s.subval(e,re,r,rp)
	return (r&REASON_EFFECT)~=0
end

-- 2. Destroy to Trigger Phase-Skip Filter
function s.desfilter(c)
	return (c:IsLocation(LOCATION_HAND+LOCATION_DECK) or c:IsFaceup()) 
		and (c:IsSetCard(0x989) or (c:IsAttribute(ATTRIBUTE_FIRE) and c:GetDefense() == 0)) -- Replace 0x1fff with your "Pyrea" SetCode
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_ONFIELD,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_ONFIELD)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_ONFIELD,0,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		-- Ask player if they want to apply the Once Per Duel effect
		if Duel.GetCustomActivityCount(id,tp,ACTIVITY_CHAIN)==0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.RegisterFlagEffect(tp,id,0,0,1) -- Lock Once Per Duel globally
			
			-- Set up the skipping mechanism
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
			e1:SetTargetRange(1,1) -- Affects both players
			e1:SetCode(EFFECT_SKIP_PHASE)
			e1:SetLabel(tp) -- Store your ID to recognize your turn later
			e1:SetValue(s.skipval)
			Duel.RegisterEffect(e1,tp)

			-- Opponent takes no damage after this resolves
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_FIELD)
			e2:SetCode(EFFECT_CHANGE_DAMAGE)
			e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e2:SetTargetRange(0,1) -- Target opponent
			e2:SetValue(0)
			Duel.RegisterEffect(e2,tp)
			
			local e3=e2:Clone()
			e3:SetCode(EFFECT_NO_EFFECT_DAMAGE)
			Duel.RegisterEffect(e3,tp)

			-- Also skip your Main Phase 2 this turn (if applicable) or on the resume turn
			local e4=Effect.CreateEffect(e:GetHandler())
			e4:SetType(EFFECT_TYPE_FIELD)
			e4:SetCode(EFFECT_SKIP_PHASE)
			e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e4:SetTargetRange(1,0)
			e4:SetValue(PHASE_MAIN2)
			e4:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN,1)
			Duel.RegisterEffect(e4,tp)
		end
	end
end

-- 3. Dynamic Skip Engine
function s.skipval(e,phase)
	local tp=e:GetLabel()
	
	-- Check if it is currently YOUR turn and the phase entering is the BATTLE PHASE
	if Duel.GetTurnPlayer()==tp and phase==PHASE_BATTLE then
		-- We found your Battle Phase! Turn off the skip engine completely so you can play.
		e:Reset()
		return false
	end
	
	-- Otherwise, skip whatever phase is trying to happen right now
	return true
end