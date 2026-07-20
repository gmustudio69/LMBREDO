--Overheat Detonator
local s,id,o=GetID()
function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e0:SetRange(LOCATION_MZONE)
	e0:SetTarget(s.rmtarget)
	e0:SetTargetRange(LOCATION_ALL,LOCATION_ALL)
	e0:SetValue(LOCATION_HAND)
	c:RegisterEffect(e0)
--On Normal or Special Summon: Owner destroys 1 "Pyrea" Trap from Deck or face-up field
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	local e2_sp=e2:Clone()
	e2_sp:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2_sp)

	--Trigger Summon: Opponent special summons a non-FIRE monster from Deck/Extra Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.spcon1)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	
	--Trigger Summon: Or at the start of the Battle Phase
	local e4=e3:Clone()
	e4:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e4:SetCondition(s.spcon2)
	c:RegisterEffect(e4)
end
---------------------------------------------------
-- REPLACEMENT: destroy → add to hand
---------------------------------------------------
function s.rmtarget(e,c)
	return c:IsReason(REASON_DESTROY)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return eg:IsExists(s.repfilter,1,nil)
	end
	return true
end

function s.repval(e,c)
	return s.repfilter(c)
end
-- 2. Summon Trigger Functions
function s.desfilter(c)
	return c:IsSetCard(0x989) and c:IsType(TYPE_TRAP) and c:IsDestructable()
		and (c:IsLocation(LOCATION_DECK) or c:IsFaceup())
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local owner=e:GetHandler():GetOwner()
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_DECK|LOCATION_ONFIELD,0,1,nil,owner) 
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,owner,LOCATION_DECK|LOCATION_ONFIELD)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local owner=e:GetHandler():GetOwner()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	-- Target filters checking the owner's possession fields specifically
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_DECK|LOCATION_ONFIELD,0,1,1,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- 3. Special Summon Trigger & Execution Functions
function s.nonfirefilter(c,tp)
	return c:IsSummonPlayer(1-tp) 
		and not c:IsAttribute(ATTRIBUTE_FIRE) 
		and (c:IsSummonLocation(LOCATION_DECK) or c:IsSummonLocation(LOCATION_EXTRA))
end

function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.nonfirefilter,1,nil,tp)
end

function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return true
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return (Duel.GetLocationCount(tp,LOCATION_MZONE)>0 or Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0)
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	local b2=Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
	local sptp=tp
	
	if b1 and b2 then
		-- Prompt choice: 0 for your side, 1 for your opponent's side
		if Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))==1 then
			sptp=1-tp
		end
	elseif b2 then
		sptp=1-tp
	elseif not b1 then
		return 
	end
	
	Duel.SpecialSummon(c,0,tp,sptp,false,false,POS_FACEUP)
end