--Pyrea - Sacred Ember
local s,id=GetID()
function s.initial_effect(c)
	--Activate: Choose 1 of 2 effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--If destroyed by card effect: Set this card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,3))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

-- Archetype definition
s.listed_names={id}

-- Option 1 Filter: "Pyrea" card to destroy from Deck or Face-up Field
function s.desfilter1(c)
	return c:IsSetCard(0x989) and c:IsDestructable()
		and (c:IsLocation(LOCATION_DECK) or c:IsFaceup())
end

-- Target Logic for Main Activation
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Check conditions for Option 1
	local b1=Duel.IsExistingMatchingCard(s.desfilter1,tp,LOCATION_DECK|LOCATION_ONFIELD,0,1,nil)
	-- Check conditions for Option 2 (Must control a monster to destroy)
	local b2=Duel.IsExistingMatchingCard(Card.IsDestructable,tp,LOCATION_MZONE,0,1,nil)
	
	if chk==0 then return b1 or b2 end
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,2))+1
	end
	
	e:SetLabel(op)
	if op==0 then
		e:SetCategory(CATEGORY_DESTROY)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_DECK|LOCATION_ONFIELD)
	else
		e:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_MZONE)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,0,LOCATION_ONFIELD)
	end
end

-- Operation Logic for Main Activation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=e:GetLabel()
	if op==0 then
		-- Effect 1: Destroy 1 "Pyrea" card from Deck or face-up field
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,s.desfilter1,tp,LOCATION_DECK|LOCATION_ONFIELD,0,1,1,c)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	else
		-- Effect 2: Destroy 1 monster you control, then bounce 1 card on the field
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_MZONE,0,1,1,nil)
		if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
			-- Check if there's a card on the field to return to hand
			if Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) 
				and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
				local hg=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
				if #hg>0 then
					Duel.HintSelection(hg)
					Duel.SendtoHand(hg,nil,REASON_EFFECT)
				end
			end
		end
	end
end

-- Re-set Effect Functions
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_EFFECT)~=0
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SSet(tp,c)
	end
end