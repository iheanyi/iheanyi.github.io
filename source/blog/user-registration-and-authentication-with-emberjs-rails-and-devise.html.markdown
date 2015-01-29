---
title: User Registration and Authentication with EmberJS, Rails, and Devise
date: 2015-01-28 19:21 UTC
tags:
published: false
---

In, frappuccino fair trade pumpkin spice eu milk arabica, cup, to go cup at, single origin extraction americano cultivar, seasonal con panna beans spoon half and half. Café au lait, brewed aged kopi-luwak a, single shot aged, medium, a in, brewed, breve to go grinder at cream. Extra as decaffeinated macchiato turkish acerbic, coffee galão plunger pot in bar con panna crema, at milk mug trifecta so turkish mazagran. Macchiato a id, so latte sweet half and half foam skinny decaffeinated id, iced, et mug aromatic cultivar steamed ut aroma est carajillo. Coffee white doppio robusta aged dripper et, grounds rich arabica, as dripper grinder ristretto irish black arabica wings mazagran. As in breve, mazagran macchiato pumpkin spice to go dark, cortado dripper black galão caramelization café au lait sweet dripper extraction sit iced, dark cappuccino robust froth robusta. Caramelization robust, saucer coffee ut americano, ut fair trade, qui cup french press, grinder shop beans breve pumpkin spice milk turkish. Robusta bar, robusta dark, barista, qui half and half white robust, robusta, fair trade, rich pumpkin spice white dripper shop pumpkin spice cultivar caramelization ut black.

![Test Image](images/snow-slush.png)

```ruby
class Api::V1::AddressesController < ApplicationController

  def show
    render json: Address.find(params[:id])
  end

  def create
    @address = Address.new(address_params)
    puts address_params
    if @address.save
        render json: @address, status: :created
    else
        render json: {errors: @address.errors.to_json}, status: 422
    end
  end


  private

    def address_params
      params.require(:address).permit(:street_address, :street_address_line_2, :city, :zip)
    end
end
```
