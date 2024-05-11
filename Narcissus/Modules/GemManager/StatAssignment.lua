local _, addon = ...


function NarciGemManagerMixin:AcquireStatButton()
    if not self.slotButtons then
        self.slotButtons = {};
        self.numSlotButtons = 0;
    end

    local index = self.numSlotButtons + 1;
    self.numSlotButtons = index;

    if not self.slotButtons[index] then
        local button = CreateTraitButton(self.SlotFrame, shape);
        button.index = index;
        self.slotButtons[index] = button;
    end

    self.slotButtons[index]:Show();

    if shape then
        self.slotButtons[index]:SetShape(shape);
    end

    return self.slotButtons[index]
end