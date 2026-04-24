local s,id=GetID()
s.listed_names={13131313}
function s.initial_effect(c)
	-- 1. Activate: Destroy all opponent's monsters on attack declaration
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY + CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetCountLimit(1,id,EFFECT_COUNT_LIMIT_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.BAYONETTA = 13131313

-- 1. Activation Condition: Only 1 monster and it must be Bayonetta
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
	return #g==1 and g:GetFirst():IsCode(s.BAYONETTA) and tp~=Duel.GetTurnPlayer()
end

-- 2. Target: All opponent's monsters
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end

-- 3. Operation: Destroy and inflict combined ATK damage
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		-- Destroy monsters and check which ones were actually destroyed
		local ct=Duel.Destroy(g,REASON_EFFECT)
		if ct>0 then
			local dg=Duel.GetOperatedGroup()
			local sum=0
			local tc=dg:GetFirst()
			while tc do
				local atk=tc:GetPreviousAttackOnField()
				if atk<0 then atk=0 end
				sum=sum+atk
				tc=dg:GetNext()
			end
			-- Inflict damage equal to combined ATK
			Duel.Damage(1-tp,sum,REASON_EFFECT)
		end
	end
end