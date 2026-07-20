--<World Breaker> Titan of the Grid
local s,id=GetID()
function s.initial_effect(c)
	--3+ Level 13 monsters
	Xyz.AddProcedure(c,nil,13,3)
	c:EnableReviveLimit()
	--Cannot be destroyed by battle
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e0:SetValue(1)
	c:RegisterEffect(e0)
	--Opponent cannot target other cards if you control "<World Decoder> Ellie"
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_ONFIELD,LOCATION_ONFIELD)
	e2:SetCondition(s.tgcon)
	e2:SetTarget(s.tgtg)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
	-- Snap-lock ATK/DEF instantly upon Xyz Summon without starting a chain link
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCondition(s.statcon)
	e3:SetOperation(s.statop)
	c:RegisterEffect(e3)

	--Quick Effect: Detach 1, destroy 1 card, then optionally lock its zone
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.descon)
	e5:SetCost(Cost.DetachFromSelf(1))
	e5:SetTarget(s.destg)
	e5:SetOperation(s.desop)
	c:RegisterEffect(e5)

	--Battle Phase Start: Board wipe and gain a 3rd attack
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_DESTROY)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e6:SetRange(LOCATION_MZONE)
	e6:SetTarget(s.bptg)
	e6:SetOperation(s.bpop)
	c:RegisterEffect(e6)
end

-- 1. Protection Condition Filters
function s.elliefilter(c)
	return c:IsFaceup() and c:IsCode(220405) -- Replace 98765432 with the actual card ID of "<World Decoder> Ellie"
end

function s.tgcon(e)
	return Duel.IsExistingMatchingCard(s.elliefilter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end

function s.tgtg(e,c)
	return c~=e:GetHandler()
end

-- Permanent Stat Lock (Non-Chain Link Listener)
function s.statcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.statop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mats=c:GetOverlayCount()
	if mats>0 then
		-- Set Permanent Base ATK
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_BASE_ATTACK)
		e1:SetValue(mats*1000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
		
		-- Set Permanent Base DEF
		local e2=e1:Clone()
		e2:SetCode(EFFECT_SET_BASE_DEFENSE)
		c:RegisterEffect(e2)
	end
end

-- 3. Intercept & Zone Lock Logic
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler()~=e:GetHandler()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		local seq=tc:GetSequence()
		local loc=tc:GetLocation()
		local p=tc:GetControler()
		
		if Duel.Destroy(tc,REASON_EFFECT)>0 then
			-- Verify it was in a usable, valid Main Monster Zone or Spell & Trap Zone
			if (loc==LOCATION_MZONE or loc==LOCATION_SZONE) and seq<5 then
				if c:IsFaceup() and c:IsRelateToEffect(e) then
					Duel.BreakEffect()
					
					-- Step 1: Calculate the exact zone bitmask
					local zone = 1 << seq
					if loc == LOCATION_SZONE then
						zone = zone << 8 -- Shift to SZONE bits
					end
					if p == 1-tp then
						zone = zone << 16 -- Shift to opponent's field bits if opponent controlled it
					end
					
					-- Step 2: Register the continuous lock linked to this card
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_FIELD)
					e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
					e1:SetCode(EFFECT_DISABLE_FIELD)
					e1:SetRange(LOCATION_MZONE)
					e1:SetOperation(function(e) return zone end)
					-- RESETS_STANDARD ensures the lock breaks if Titan leaves the field/gets flipped
					e1:SetReset(RESET_EVENT|RESETS_STANDARD)
					c:RegisterEffect(e1)
				end
			end
		end
	end
end

-- 4. Battle Phase Wipe and Multi-Attack
function s.bpfilter(c,hc)
	return c~=hc and c:IsType(TYPE_MONSTER) and c:IsDestructable()
end

function s.bptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.bpfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,c,c) end
	local g=Duel.GetMatchingGroup(s.bpfilter,tp,LOCATION_MZONE,LOCATION_MZONE,c,c)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.bpop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.bpfilter,tp,LOCATION_MZONE,LOCATION_MZONE,c,c)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			-- Grants the ability to attack up to 3 times during this battle phase
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EXTRA_ATTACK)
			e1:SetValue(2)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE)
			c:RegisterEffect(e1)
		end
	end
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	--Cannot Special Summon monsters, except "Gimmick Puppet" monsters
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c) return not c:IsSetCard(SET_GIMMICK_PUPPET) end)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end