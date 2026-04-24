local s,id=GetID()

function s.initial_effect(c)
	-- 1. Archetype Treatment: Always Umbra Witch and Lumen Sage
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_ADD_SETCODE)
	e1:SetValue(0x7f6) -- Umbra Witch
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetValue(0xcb0) -- Lumen Sage
	c:RegisterEffect(e2)

	-- 2. Protection: Cannot be targeted or destroyed by card effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetValue(1)
	c:RegisterEffect(e4)

	-- 3. Special Summon: Tribute 2 (incl. 1 Infernal Demon 0x704)
	-- Rodin HIMSELF is not a demon, but he "uses" one to enter the field.
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_HAND + LOCATION_GRAVE)
	e5:SetCountLimit(1,id)
	e5:SetCost(s.spcost)
	e5:SetTarget(s.sptg)
	e5:SetOperation(s.spop)
	c:RegisterEffect(e5)

	-- 4. Dynamic Stats: Highest Opponent ATK + 1000
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_SET_ATTACK_FINAL)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetValue(s.adval)
	c:RegisterEffect(e6)
	local e7=e6:Clone()
	e7:SetCode(EFFECT_SET_DEFENSE_FINAL)
	c:RegisterEffect(e7)
end

-- Archetype IDs
s.INFERNAL_DEMON = 0x704
s.LUMEN_SAGE = 0xcb0
s.UMBRA_WITCH = 0x7f6

-- Special Summon Cost: Tribute 2 (1 must be Infernal Demon)
function s.rescon(sg,e,tp,mg)
	return sg:IsExists(Card.IsSetCard,1,nil,s.INFERNAL_DEMON)
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local rg=Duel.GetReleaseGroup(tp)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>-2
		and rg:GetCount()>=2 and aux.SelectUnselectGroup(rg,e,tp,2,2,s.rescon,0) end
	local g=aux.SelectUnselectGroup(rg,e,tp,2,2,s.rescon,1,tp,aux.Stringid(id,0))
	Duel.Release(g,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ATK/DEF Scaling Logic: Opponent's strongest monster + 1000
function s.adval(e,c)
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	local g2=g:Filter(function(tc) return not tc:IsCode(id) end, nil)
	
	if #g2==0 then return 1000 end
	
	local max_atk=g2:GetMaxGroup(Card.GetAttack):GetFirst():GetAttack()
	return max_atk + 1000
end