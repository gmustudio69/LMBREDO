--Nocturne Gear - Secret hideout
local s,id=GetID()
function s.initial_effect(c)
	--Activate Field Spell
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	c:RegisterEffect(e0)

	--Extra Normal Summon (1 extra Psychic Normal Summon per turn)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(LOCATION_HAND|LOCATION_MZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_PSYCHIC))
	c:RegisterEffect(e1)

	--Banish 1 Psychic to Special Summon 1 "Nocturne Gear" with a different Level
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- Cost Filter: Must be a Psychic monster on field or GY that is able to be banished
function s.costfilter(c,e,tp)
	local lv=c:GetLevel()
	return c:IsRace(RACE_PSYCHIC) and c:IsAbleToRemoveAsCost() and lv>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK|LOCATION_GRAVE|LOCATION_REMOVED,0,1,c,e,tp,lv)
end

-- Target Filter: "Nocturne Gear" monster with a different Level than the banished cost card
function s.spfilter(c,e,tp,lv)
	return c:IsSetCard(0x999) -- Replace 0x999 with your actual "Nocturne Gear" archetype ID
		and c:IsType(TYPE_MONSTER)
		and c:HasLevel()
		and not c:IsLevel(lv)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and (not c:IsLocation(LOCATION_REMOVED) or c:IsFaceup())
end

-- 1. Cost & Target Logic
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_MZONE|LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_MZONE|LOCATION_GRAVE,0,1,1,nil,e,tp)
	e:SetLabel(g:GetFirst():GetLevel())
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- Cost already verifies target availability
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE|LOCATION_REMOVED)
end

-- 2. Special Summon Operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local lv=e:GetLabel()
	if not lv then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK|LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil,e,tp,lv)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end