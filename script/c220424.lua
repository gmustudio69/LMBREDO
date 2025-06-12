--Light Fox Maiden
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,nil,2,2,s.lcheck)

	--Cannot be used as Link Material the turn it's Link Summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCondition(s.linkcon)
	e0:SetValue(1)
	c:RegisterEffect(e0)

	--Cannot target LIGHT monsters this card points to
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetTarget(s.etarget)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	--Search LIGHT monster of same type
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id) -- Once per turn
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- Link Materials: must include a LIGHT
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_LIGHT,lc,sumtype,tp)
end
-- Cannot be used as Link Material the turn it's summoned
function s.linkcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- LIGHT monsters this card points to cannot be targeted
function s.etarget(e,c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and e:GetHandler():GetLinkedGroup():IsContains(c)
end

function s.banfilter(c,tp)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and (c:IsAbleToRemoveAsCost() or c:IsLocation(LOCATION_MZONE))
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,c:GetRace())
end
function s.thfilter(c,race)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(race) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.banfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil,tp) end
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.banfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil,tp)
	if #g>0 then
		local race=g:GetFirst():GetRace()
		if Duel.Remove(g,POS_FACEUP,REASON_COST)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,race)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
				-- Restrict to LIGHT Special Summons
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_FIELD)
				e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
				e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
				e1:SetTargetRange(1,0)
				e1:SetTarget(s.splimit)
				e1:SetReset(RESET_PHASE+PHASE_END)
				Duel.RegisterEffect(e1,tp)
			end
		end
	end
end
function s.splimit(e,c)
	return not c:IsAttribute(ATTRIBUTE_LIGHT)
end
