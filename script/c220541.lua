local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon procedure
	c:EnableReviveLimit()
	--Pendulum.AddProcedure(c)
	Link.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_EFFECT),2,2)

	-- Pendulum Effect
	local pe1=Effect.CreateEffect(c)
	pe1:SetDescription(aux.Stringid(id,0))
	pe1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	pe1:SetType(EFFECT_TYPE_IGNITION)
	pe1:SetRange(LOCATION_PZONE)
	pe1:SetCountLimit(1,id)
	pe1:SetCost(s.tkcost)
	pe1:SetTarget(s.tktg)
	pe1:SetOperation(s.tkop)
	c:RegisterEffect(pe1)

	-- Monster Effect 1: Trigger on Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id+100)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	
	-- Monster Effect 2: Same trigger when summoned to a linked zone
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.linkcon)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Monster Effect 3: If sent to Extra Deck face-up, place in Pendulum Zone
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_TO_DECK)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,id+200)
	e4:SetTarget(s.pzontg)
	e4:SetOperation(s.pzonop)
	c:RegisterEffect(e4)
end

-- Pendulum Effect Logic
function s.tkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,800) end
	Duel.PayLPCost(tp,800)
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
		and Duel.IsPlayerCanSpecialSummonMonster(tp,220542,0,TYPES_TOKEN,0,0,1,RACE_WARRIOR,ATTRIBUTE_FIRE) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
end
-- Fix 2: Token Summoning to Linked Zone
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local zone=c:GetLinkedZone(tp)
	-- Check if there is a valid zone AND space for the token
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		if not Duel.IsPlayerCanSpecialSummonMonster(tp,220542,0,TYPES_TOKEN,0,0,1,RACE_WARRIOR,ATTRIBUTE_FIRE) then return end
		local token=Duel.CreateToken(tp,220542)
		-- The zone argument in SpecialSummon restricts it to that specific zone
		Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Monster Effect Logic
function s.linkcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c,lc) return lc:GetLinkedGroup():IsContains(c) end,1,nil,e:GetHandler())
end
-- Fix 1: Targeting Logic in Monster Effect
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	-- We need 1 monster I control AND 1 other card on the field
	if chk==0 then 
		return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingTarget(function(c,ec) return c~=ec end,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,e:GetHandler()) 
	end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	-- Ensure the second target is not the first target
	local g2=Duel.SelectTarget(tp,function(c,tc) return c~=tc end,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,g1:GetFirst(),g1:GetFirst())
	
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g1,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	-- Retrieve all cards that are still on the field/relevant
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,e)
	
	-- Ask the player to choose which of the two targets to Destroy, 
	-- then the other will be Banished.
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local tc1=g:Select(tp,1,1,nil):GetFirst()
	
	if tc1 then
		g:RemoveCard(tc1) -- Remove the chosen one from the group
		local tc2=g:GetFirst() -- The remaining card is the one to be banished
		
		-- Perform the actions
		if Duel.Destroy(tc1,REASON_EFFECT)>0 and tc2 then
			Duel.BanishUntilEndPhase(tc2,tp)
		end
	end
end

-- Extra Deck to Pendulum Zone Logic
function s.pzontg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1) end
end
function s.pzonop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)) then return end
	Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	local e1=Effect.CreateEffect(c)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetValue(TYPE_SPELL+TYPE_LINK)
	c:RegisterEffect(e1)
end