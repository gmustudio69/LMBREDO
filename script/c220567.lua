-- Custom Spell Card
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- First time each FIRE Warrior would be destroyed by effect, it is not
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.subtg)
	e2:SetValue(s.subval)
	c:RegisterEffect(e2)

	-- Once per turn: Destroy and apply the Turn-Skip effect (Once per Duel)
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

-- Substitute Filters
function s.subtg(e,c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR)
end
function s.subval(e,re,r,rp)
	if (r&REASON_EFFECT)~=0 then
		return 1
	else return 0 end
end

-- Destroy Filters
function s.desfilter(c)
	return (c:IsLocation(LOCATION_HAND+LOCATION_DECK) or c:IsFaceup())
		and ((c:IsAttribute(ATTRIBUTE_FIRE) and c:GetDefense()==0) or c:IsSetCard(0x989)) -- Replace 0xXXXX with your custom "Pyrea" Archetype Hex Code
		and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_ONFIELD,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_ONFIELD)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_ONFIELD,0,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		-- Check Once Per Duel requirement before executing the major text block
		if Duel.GetFlagEffect(tp,id)==0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.RegisterFlagEffect(tp,id,0,0,1) -- Once per duel flag registration

			-- 1. No Damage to Opponent restriction
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_CHANGE_DAMAGE)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e1:SetTargetRange(0,1)
			e1:SetValue(0)
			e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1) -- Ends after opponent's next turn finishes naturally
			Duel.RegisterEffect(e1,tp)
			
			local e2=e1:Clone()
			e2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
			Duel.RegisterEffect(e2,tp)

			-- 2. Skip Main Phase 2 restriction
			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetType(EFFECT_TYPE_FIELD)
			e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e3:SetCode(EFFECT_SKIP_M2)
			e3:SetTargetRange(1,0)
			e3:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN,1)
			Duel.RegisterEffect(e3,tp)

			-- 3. Dynamic Phase Skipper Engine (Intercepts game flow until your real battle phase arrives)
			local e4=Effect.CreateEffect(e:GetHandler())
			e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e4:SetCode(EVENT_PHASE_START)
			e4:SetLabel(tp) -- Save who activated it to track "your next battle phase"
			e4:SetCondition(s.skipcon)
			e4:SetOperation(s.skipop)
			Duel.RegisterEffect(e4,tp)
		end
	end
end

-- Phase Skipper Core logic
function s.skipcon(e,tp,eg,ep,ev,re,r,rp)
	local act_player = e:GetLabel() -- The player who used this card
	local turn_p = Duel.GetTurnPlayer()
	local phase = Duel.GetCurrentPhase()

	-- Standard check: If it's your turn, and it's the Battle Phase...
	if turn_p == act_player and phase == PHASE_BATTLE_START then
		-- AND you are legally allowed to enter the battle phase (not skipped by rules or another card)
		if not Duel.IsPlayerAffectedByEffect(act_player, EFFECT_CANNOT_BP) 
		   and not Duel.IsPlayerAffectedByEffect(act_player, EFFECT_SKIP_BP) then
			-- We reached the target! Self-destruct the skipper and let the phase play out.
			e:Reset()
			return false
		end
	end
	return true -- Skip everything else
end

function s.skipop(e,tp,eg,ep,ev,re,r,rp)
	-- Instantly bypass whatever phase just opened up
	Duel.SkipPhase(Duel.GetTurnPlayer(), Duel.GetCurrentPhase(), RESET_PHASE+Duel.GetCurrentPhase(), 1)
end